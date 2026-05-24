// Copyright (C) 2026 Katsute | Licensed under CC BY-NC-SA 4.0

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
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Random Size Modifier",
    author = "Katsute",
    description = "Modifier that gives each player a unique random size.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_size_random_min", "0.25", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_size_random_max", "1.3",  "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_size_random", "rrm");
}

public void OnPluginEnd()
{
    RemoveSize();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Random Size", 0.0, 0.0, false, RRM_Callback_RandomSize);
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

public int RRM_Callback_RandomSize(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        SetSize();
    else
        RemoveSize();
    return gEnabled;
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
        SetPlayerSize(client);
}

public void OnClientPostAdminCheck(int client)
{
    if(!gEnabled)
        return;
    SetPlayerSize(client);
}

void SetPlayerSize(int client)
{
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", RandomFloat(gMin, gMax));
}

void SetSize()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i))
            SetPlayerSize(i);
}

void RemoveSize()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i))
            SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}