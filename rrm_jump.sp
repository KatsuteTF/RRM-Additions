// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

int gEnabled = 0;

public Plugin myinfo =
{
    name = "[RRM] Jump Modifier",
    author = "Katsute",
    description = "Modifier that forces players to constantly jump.",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_jump", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Jump", 0.0, 0.0, false, RRM_Callback_Jump);
}

public int RRM_Callback_Jump(bool enable, float value)
{
    gEnabled = enable;
    return gEnabled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon,
    int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    buttons |= IN_JUMP;
    return Plugin_Changed;
}
