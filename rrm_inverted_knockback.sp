// Copyright (C) 2026 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "2.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

int gEnabled = 0;
float gMul = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Inverted Knockback Modifier",
    author = "Katsute",
    description = "Modifier that inverts and scales knockback force, pulling the victim toward the attacker.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_inverted_knockback_min", "-5.0", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_inverted_knockback_max", "0.0", "Maximum value for the random number generator.");

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

    AutoExecConfig(true, "rrm_inverted_knockback", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Inverted Knockback", gMin, gMax, false, RRM_Callback_InvertedKnockback);
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

public int RRM_Callback_InvertedKnockback(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gMul = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= victim <= MaxClients) || !IsClientInGame(victim) || !IsPlayerAlive(victim))
        return Plugin_Continue;

    damageForce[0] *= gMul;
    damageForce[1] *= gMul;
    damageForce[2] *= gMul;
    return Plugin_Changed;
}
