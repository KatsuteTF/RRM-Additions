// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

#define TFCond_Null view_as<TFCond>(-1)

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

public Plugin myinfo = {
    name = "[RRM] Random Powerup Modifier",
    author = "Katsute",
    description = "Modifier that grants a random powerup.",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AddCommandListener(OnDropItem, "dropitem");
    HookEvent("player_changeclass", OnChangeClass);
    HookEvent("player_spawn", OnPlayerSpawn);

    AutoExecConfig(true, "rrm_powerup_random", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Random Powerup", 0.0, 0.0, false, RRM_Callback_Powerup);
}

public int RRM_Callback_Powerup(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        int ent;
        while((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
            SDKHook(ent, SDKHook_EndTouchPost, OnExitResupply);

        for(int i = 1; i <= MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                ApplyPowerup(i);
    }
    else
    {
        int ent;
        while((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
            SDKUnhook(ent, SDKHook_EndTouchPost, OnExitResupply);

        for(int i = 1; i <= MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                RemovePowerup(i);
    }
    return gEnabled;
}

public void OnEntityCreated(int ent, const char[] classname)
{
    if(gEnabled && strncmp(classname, "item_power", 10) == 0 && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
}

public void OnChangeClass(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(gEnabled)
    {
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        if(IsClientInGame(client))
            ApplyPowerup(client);
    }
}

public void OnPlayerSpawn(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(gEnabled)
    {
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        if(IsClientInGame(client))
            ApplyPowerup(client);
    }
}

public void OnExitResupply(const int resupply, const int client)
{
    if(gEnabled && 0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
        ApplyPowerup(client);
}

public Action OnDropItem(const int client, const char[] cmd, any args)
{
    if(gEnabled)
        return Plugin_Handled;
    return Plugin_Continue;
}

void ApplyPowerup(const int client)
{
    RemovePowerup(client);
    TFCond cond = gPowerups[GetURandomInt() % sizeof(gPowerups)];
    gPlayerCond[client] = cond;
    TF2_AddCondition(client, cond);
    TF2_RegeneratePlayer(client);
}

void RemovePowerup(const int client)
{
    TFCond cond = gPlayerCond[client];
    if(cond != TFCond_Null && TF2_IsPlayerInCondition(client, cond))
        TF2_RemoveCondition(client, cond);
    gPlayerCond[client] = TFCond_Null;
}
