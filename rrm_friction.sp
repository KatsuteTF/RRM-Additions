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
float gMul = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Friction Modifier",
    author = "Katsute",
    description = "Modifier changes friction.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_friction_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_friction_max", "1.0", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_friction", "rrm");
}

public void OnPluginEnd()
{
    DisableEffect();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Friction", gMin, gMax, false, RRM_Callback_Effect);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue){
    if (StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cMin)
        gMin = fNewValue;
    else if(convar == cMax)
        gMax = fNewValue;
}

public int RRM_Callback_Effect(bool enable, float value)
{
    gEnabled = enable;
    gMul = value;
    if(gEnabled)
        EnableEffect();
    else
        DisableEffect();
    return enable;
}

void EnableEffect()
{
    ServerCommand("sv_friction %f", 4 * gMul);
}

void DisableEffect()
{
    ServerCommand("sv_friction 4");
}