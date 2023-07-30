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

public Plugin myinfo =
{
    name = "[RRM] Friendly Fire Modifier",
    author = "Katsute",
    description = "Modifier that sets game to friendly fire",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_friendly", "rrm");
}

public void OnPluginEnd()
{
    DisableFriendly();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Friendly Fire", 0.0, 0.0, false, RRM_Callback_Friendly);
}

public int RRM_Callback_Friendly(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        EnableFriendly();
    else
        DisableFriendly();
    return enable;
}

void EnableFriendly()
{
    ServerCommand("mp_friendlyfire 1");
}

void DisableFriendly()
{
    ServerCommand("mp_friendlyfire 0");
}