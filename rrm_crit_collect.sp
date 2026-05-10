// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

int gEnabled = 0;
ConVar cDuration = null;
float gDuration = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Crit Collect Modifier",
    author = "Katsute",
    description = "Modifier that grants crits on ammo or health pickup.",
    version = "1.0"
};

public void OnPluginStart()
{
    cDuration = CreateConVar("rrm_crit_collect_duration", "5.0", "Duration for crits after pickup.");

    cDuration.AddChangeHook(OnConvarChanged);

    gDuration = cDuration.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_crit_collect", "rrm");

    HookExistingPickups();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Crit Collect", 0.0, 0.0, false, RRM_Callback_CritCollect);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;
    if(convar == cDuration)
        gDuration = StringToFloat(newValue);
}

public int RRM_Callback_CritCollect(bool enable, float value)
{
    gEnabled = enable;
    if(!gEnabled)
    {
        for(int i = 1; i <= MaxClients; i++)
            if(IsClientInGame(i) && TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged))
                TF2_RemoveCondition(i, TFCond_Kritzkrieged);
    }
    return gEnabled;
}

void HookExistingPickups()
{
    static const char pickupClasses[][] = {
        "item_healthkit_small", "item_healthkit_medium", "item_healthkit_full",
        "tf_ammo_pack"
    };
    for(int c = 0; c < sizeof(pickupClasses); c++)
    {
        int ent = -1;
        while((ent = FindEntityByClassname(ent, pickupClasses[c])) != -1)
            SDKHook(ent, SDKHook_StartTouchPost, OnPickupTouch);
    }
}

public void OnEntityCreated(int ent, const char[] classname)
{
    if(strncmp(classname, "item_healthkit", 14) == 0 || StrEqual(classname, "tf_ammo_pack"))
        SDKHook(ent, SDKHook_StartTouchPost, OnPickupTouch);
}

public void OnPickupTouch(int ent, int other)
{
    if(!gEnabled)
        return;
    if(!(1 <= other <= MaxClients) || !IsClientInGame(other) || !IsPlayerAlive(other))
        return;

    DataPack pack = new DataPack();
    pack.WriteCell(EntIndexToEntRef(ent));
    pack.WriteCell(other);
    RequestFrame(OnPickupFrame, pack);
}

public void OnPickupFrame(any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int entref = pack.ReadCell();
    int client  = pack.ReadCell();
    delete pack;

    if(!gEnabled)
        return;
    if(EntRefToEntIndex(entref) != INVALID_ENT_REFERENCE)
        return;
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    TF2_AddCondition(client, TFCond_Kritzkrieged, gDuration);
}
