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
    name = "[RRM] Damage Score Modifier",
    author = "Katsute",
    description = "Modifier that adds bonus damage based on player score.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_damage_score_min", "1.0", "Minimum bonus damage per kill.");
    cMax = CreateConVar("rrm_damage_score_max", "5.0", "Maximum bonus damage per kill.");

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

    AutoExecConfig(true, "rrm_damage_score", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Damage Score", gMin, gMax, false, RRM_Callback_DamageScore);
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

public int RRM_Callback_DamageScore(bool enable, float value)
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
        }
    }
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    int frags = GetClientFrags(attacker);
    if(frags <= 0)
        return Plugin_Continue;

    damage += float(frags) * gValue;
    return Plugin_Changed;
}
