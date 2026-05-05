// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

#define IN_JUMP 2

int gEnabled = 0;
bool gJump[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[RRM] Jump Shot Modifier",
    author = "Katsute",
    description = "Modifier that makes players jump when they are shot.",
    version = "1.0"
};

public void OnPluginStart()
{
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
    RRM_Register("Jump Shot", 0.0, 0.0, false, RRM_Callback_JumpShot);
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public int RRM_Callback_JumpShot(bool enable, float value)
{
    gEnabled = enable;
    if(!gEnabled)
    {
        for(int i = 1; i <= MaxClients; i++)
            gJump[i] = false;
    }
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

    gJump[victim] = true;

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon,
    int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!gEnabled || !gJump[client])
        return Plugin_Continue;

    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    gJump[client] = false;
    buttons |= IN_JUMP;
    return Plugin_Changed;
}
