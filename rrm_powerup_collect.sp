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
TFCond gPlayerCond[MAXPLAYERS + 1];

static const TFCond gPowerups[] = {
    TFCond_RuneAgility,
    TFCond_RuneHaste,
    TFCond_PlagueRune,
    TFCond_RunePrecision,
    TFCond_RuneResist,
    TFCond_RuneStrength,
    TFCond_RuneVampire
};

public Plugin myinfo =
{
    name = "[RRM] Powerup Collect Modifier",
    author = "Katsute",
    description = "Modifier that grants a random powerup on ammo or health pickup.",
    version = "1.0"
};

public void OnPluginStart()
{
    for(int i = 1; i <= MaxClients; i++)
        gPlayerCond[i] = TFCond_Null;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_powerup_collect", "rrm");

    HookExistingPickups();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Powerup Collect", 0.0, 0.0, false, RRM_Callback_PowerupCollect);
}

public void OnClientDisconnect(int client)
{
    gPlayerCond[client] = TFCond_Null;
}

public int RRM_Callback_PowerupCollect(bool enable, float value)
{
    gEnabled = enable;
    if(!gEnabled)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsClientInGame(i))
                continue;
            TFCond cond = gPlayerCond[i];
            if(cond != TFCond_Null && TF2_IsPlayerInCondition(i, cond))
                TF2_RemoveCondition(i, cond);
            gPlayerCond[i] = TFCond_Null;
        }
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

    ApplyPowerup(client);
}

void ApplyPowerup(int client)
{
    if(HasPowerup(client))
        return;
    TFCond cond = gPowerups[GetURandomInt() % sizeof(gPowerups)];
    gPlayerCond[client] = cond;
    TF2_AddCondition(client, cond);
}

bool HasPowerup(int client)
{
    for(int i = 0; i < sizeof(gPowerups); i++)
        if(TF2_IsPlayerInCondition(client, gPowerups[i]))
            return true;
    return false;
}
