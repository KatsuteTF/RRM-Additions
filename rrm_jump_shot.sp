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
    name = "[RRM] Jump Shot Modifier",
    author = "Katsute",
    description = "Modifier that launches players upward when they are shot.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_jump_shot_min", "200.0", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_jump_shot_max", "600.0", "Maximum value for the random number generator.");

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

    AutoExecConfig(true, "rrm_jump_shot", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Jump Shot", gMin, gMax, false, RRM_Callback_JumpShot);
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

public int RRM_Callback_JumpShot(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gValue = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= victim <= MaxClients) || !IsClientInGame(victim) || !IsPlayerAlive(victim))
        return Plugin_Continue;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;
    if(victim == attacker)
        return Plugin_Continue;

    float vel[3];
    GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", vel);
    vel[2] += gValue;
    TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

    return Plugin_Continue;
}
