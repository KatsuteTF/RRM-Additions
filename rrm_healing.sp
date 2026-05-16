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
float gMul = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Healing Modifier",
    author = "Katsute",
    description = "Modifier that multiplies healing received.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_healing_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_healing_max", "3.0", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    HookEvent("player_healed", OnPlayerHealed);

    AutoExecConfig(true, "rrm_healing", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Healing", gMin, gMax, false, RRM_Callback_Healing);
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

public int RRM_Callback_Healing(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gMul = value;
    return gEnabled;
}

public void OnPlayerHealed(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int patient = GetClientOfUserId(GetEventInt(event, "patient"));
    int amount  = GetEventInt(event, "amount");

    if(!(1 <= patient <= MaxClients) || !IsClientInGame(patient) || !IsPlayerAlive(patient))
        return;

    if(amount <= 0)
        return;

    int maxHealth = GetEntProp(patient, Prop_Data, "m_iMaxHealth");
    int curHealth = GetClientHealth(patient);

    if(gMul >= 1.0)
    {
        int bonus = RoundToFloor(float(amount) * (gMul - 1.0));
        if(bonus > 0)
            SetEntityHealth(patient, curHealth + bonus > maxHealth ? maxHealth : curHealth + bonus);
    }
    else
    {
        int penalty = RoundToFloor(float(amount) * (1.0 - gMul));
        if(penalty > 0)
            SetEntityHealth(patient, curHealth - penalty < 1 ? 1 : curHealth - penalty);
    }
}
