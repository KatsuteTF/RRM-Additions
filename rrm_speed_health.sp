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
    name = "[RRM] Speed Health Modifier",
    author = "Katsute",
    description = "Modifier that increases speed as health decreases.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_speed_health_min", "1.5", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_speed_health_max", "2.5", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_speed_health", "rrm");

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_hurt",  OnPlayerHurt);
}

public void OnPluginEnd()
{
    RemoveSpeed();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Speed Health", gMin, gMax, false, RRM_Callback_SpeedHealth);
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

public int RRM_Callback_SpeedHealth(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        gValue = value;
        for(int i = 1; i <= MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                UpdateSpeed(i);
    }
    else
        RemoveSpeed();
    return gEnabled;
}

public void OnPlayerSpawn(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
        UpdateSpeed(client);
}

public void OnPlayerHurt(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
        UpdateSpeed(client);
}

void UpdateSpeed(int client)
{
    int hp    = GetClientHealth(client);
    int maxHp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    if(maxHp <= 0)
        return;

    float ratio = 1.0 - (float(hp) / float(maxHp));
    float speed = 1.0 + (gValue - 1.0) * ratio;
    TF2Attrib_SetByName(client, "move speed bonus", speed);
}

void RemoveSpeed()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        TF2Attrib_RemoveByName(i, "move speed bonus");
    }
}
