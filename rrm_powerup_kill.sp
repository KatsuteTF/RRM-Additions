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
    name = "[RRM] Powerup Kill Modifier",
    author = "Katsute",
    description = "Modifier that grants a random powerup on kill.",
    version = "1.0"
};

public void OnPluginStart()
{
    for(int i = 1; i <= MaxClients; i++)
        gPlayerCond[i] = TFCond_Null;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_powerup_kill", "rrm");

    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Powerup Kill", 0.0, 0.0, false, RRM_Callback_PowerupKill);
}

public void OnClientDisconnect(int client)
{
    gPlayerCond[client] = TFCond_Null;
}

public int RRM_Callback_PowerupKill(bool enable, float value)
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

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client   = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(client == attacker)
        return;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
        return;

    ApplyPowerup(attacker);
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
