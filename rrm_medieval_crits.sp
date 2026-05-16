// Copyright (C) 2026 Katsute | Licensed under CC BY-NC-SA 4.0

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
    name = "[RRM] Medieval Crits Modifier",
    author = "Katsute",
    description = "Modifier that sets game to medieval with 100% melee crit chance.",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_medieval_crits", "rrm");
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
    RRM_Register("Medieval Crits", 0.0, 0.0, false, RRM_Callback_MedievalCrits);
}

public int RRM_Callback_MedievalCrits(bool enable, float value)
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
    for(int i = 1; i <= MaxClients; i++){
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
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i)){
            int health = GetClientHealth(i);
            TF2_RemoveAllWeapons(i);
            TF2_RegeneratePlayer(i);
            SetEntityHealth(i, health < 1 ? 1 : health);
        }
    }
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if(weapon == GetPlayerWeaponSlot(client, 2)){
        result = true;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}
