// Copyright (C) 2023 Katsute | Licensed under CC BY-NC-SA 4.0

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
ConVar cMin = null, cMax = null, cDuration = null;
float gMin = 0.0, gMax = 0.0, gDuration = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Fire Modifier",
    author = "Katsute",
    description = "Modifier that grants chance of fire.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_fire_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_fire_max", "1.0", "Maximum value for the random number generator.");
    cDuration = CreateConVar("rrm_fire_duration", "3.0", "Duration for fire to last on affected players.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDuration.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;
    gDuration = cDuration.FloatValue;

    for (int i = 1; i < MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
    }

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_fire", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Fire", gMin, gMax, false, RRM_Callback_Fire);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if (StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cMin)
        gMin = fNewValue;
    else if(convar == cMax)
        gMax = fNewValue;
    else if(convar == cDuration)
        gDuration = fNewValue;
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public int RRM_Callback_Fire(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
    {
        if(!(1 <= victim <= MaxClients))
            return Plugin_Continue;
        if(!IsClientInGame(victim))
            return Plugin_Continue;
        if(!(1 <= attacker <= MaxClients))
            return Plugin_Continue;
        if(!IsClientInGame(attacker))
            return Plugin_Continue;
        if(!IsPlayerAlive(victim))
            return Plugin_Continue;
        if(!TF2_IsPlayerInCondition(victim, TFCond_OnFire))
            TF2_IgnitePlayer(victim, attacker, gDuration);
    }
    return Plugin_Continue;
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}