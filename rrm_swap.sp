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
float gChance = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Swap Modifier",
    author = "Katsute",
    description = "Modifier that swaps attacker to victim's location on kill.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_swap_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_swap_max", "1.0", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_swap", "rrm");

    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Swap", gMin, gMax, false, RRM_Callback_Swap);
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

public int RRM_Callback_Swap(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
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
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
        return;

    if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);
        TeleportEntity(attacker, origin, NULL_VECTOR, NULL_VECTOR);
    }
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
