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
float gChance = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;
bool gReflecting = false;

public Plugin myinfo =
{
    name = "[RRM] Damage Reflect Chance Modifier",
    author = "Katsute",
    description = "Modifier that grants a chance to fully reflect damage back to the attacker.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_damage_reflect_chance_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_damage_reflect_chance_max", "0.5", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
    }

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_damage_reflect_chance", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Damage Reflect Chance", gMin, gMax, false, RRM_Callback_DamageReflectChance);
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
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public int RRM_Callback_DamageReflectChance(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled || gReflecting)
        return Plugin_Continue;

    if(!(1 <= victim <= MaxClients) || !IsClientInGame(victim) || !IsPlayerAlive(victim))
        return Plugin_Continue;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
        return Plugin_Continue;
    if(victim == attacker)
        return Plugin_Continue;

    if(gChance > RandomFloat(0.0, 1.0))
    {
        gReflecting = true;
        SDKHooks_TakeDamage(attacker, victim, victim, damage, damagetype);
        gReflecting = false;
        damage = 0.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
