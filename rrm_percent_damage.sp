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
float gPercent = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Percent Damage Modifier",
    author = "Katsute",
    description = "Modifier that deals a percentage of victim max health as damage.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_percent_damage_min", "0.05", "Minimum percentage of max health dealt as damage.");
    cMax = CreateConVar("rrm_percent_damage_max", "0.5",  "Maximum percentage of max health dealt as damage.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
    }

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_percent_damage", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Percent Damage", gMin, gMax, false, RRM_Callback_PercentDamage);
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

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public int RRM_Callback_PercentDamage(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gPercent = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= victim <= MaxClients) || !IsClientInGame(victim))
        return Plugin_Continue;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    int maxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
    if(maxHealth <= 0)
        return Plugin_Continue;

    damage = float(maxHealth) * gPercent;
    return Plugin_Changed;
}
