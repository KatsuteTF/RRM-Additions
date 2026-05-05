// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

int gEnabled = 0;
float gValue = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Health Score Modifier",
    author = "Katsute",
    description = "Modifier that sets max health based on player score.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_health_score_min", "5.0",  "Minimum HP gained per kill.");
    cMax = CreateConVar("rrm_health_score_max", "20.0", "Maximum HP gained per kill.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_health_score", "rrm");

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Health Score", gMin, gMax, false, RRM_Callback_HealthScore);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cMin)
        gMin = fNewValue;
    else if(convar == cMax)
        gMax = fNewValue;
}

public int RRM_Callback_HealthScore(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        gValue = value;
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsClientInGame(i))
                continue;
            SetEntProp(i, Prop_Data, "m_iFrags", 0);
            TF2Attrib_SetByName(i, "max health additive bonus", 0.0);
        }
    }
    else
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsClientInGame(i))
                continue;
            TF2Attrib_RemoveByName(i, "max health additive bonus");
        }
    }
    return gEnabled;
}

public void OnPlayerSpawn(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
        UpdateHealth(client);
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int client   = GetClientOfUserId(GetEventInt(event, "userid"));
    if(attacker == client)
        return;
    if(1 <= attacker <= MaxClients && IsClientInGame(attacker))
        UpdateHealth(attacker);
}

void UpdateHealth(int client)
{
    int frags = GetClientFrags(client);
    TF2Attrib_SetByName(client, "max health additive bonus", float(frags) * gValue);
}
