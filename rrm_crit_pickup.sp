// Copyright (C) 2026 Katsute | Licensed under CC BY-NC-SA 4.0

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
    name = "[RRM] Crit Pickups Modifier",
    author = "Katsute",
    description = "Modifier that grants crits on ammo or health pickup.",
    version = "2.0"
};

public void OnPluginStart()
{
    cDuration = CreateConVar("rrm_crit_pickup_duration", "5.0", "Duration for crits after pickup.");

    cDuration.AddChangeHook(OnConvarChanged);

    gDuration = cDuration.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    HookEvent("item_pickup", OnItemPickup);
    AutoExecConfig(true, "rrm_crit_pickup", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Crit Pickups", 0.0, 0.0, false, RRM_Callback_CritCollect);
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

public void OnItemPickup(const Event event, const char[] name, const bool dontBroadcast){
    if(!gEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    TF2_AddCondition(client, TFCond_Kritzkrieged, gDuration);
}