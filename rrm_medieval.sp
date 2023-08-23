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
    name = "[RRM] Medieval Modifier",
    author = "Katsute",
    description = "Modifier that sets game to medieval",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_medieval", "rrm");
}

public void OnPluginEnd()
{
    DisableMedieval();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Medieval", 0.0, 0.0, false, RRM_Callback_Medieval);
}

public int RRM_Callback_Medieval(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        EnableMedieval();
    else
        DisableMedieval();
    return enable;
}

void EnableMedieval()
{
    GameRules_SetProp("m_bPlayingMedieval", 1);
    for(int i = 1; i < MaxClients; i++){
        if(IsClientInGame(i)){
            int health = GetClientHealth(i);
            TF2_RemoveAllWeapons(i);
            TF2_RegeneratePlayer(i);
            SetEntityHealth(i, health < 1 ? 1 : health);
        }
    }
}

void DisableMedieval()
{
    GameRules_SetProp("m_bPlayingMedieval", 0);
    for(int i = 1; i < MaxClients; i++){
        if(IsClientInGame(i)){
            int health = GetClientHealth(i);
            TF2_RemoveAllWeapons(i);
            TF2_RegeneratePlayer(i);
            SetEntityHealth(i, health < 1 ? 1 : health);
        }
    }
}