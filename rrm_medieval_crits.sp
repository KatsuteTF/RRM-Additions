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
    description = "Modifier that sets game to medieval with 100% crit chance.",
    version = "1.0"
};

public void OnPluginStart()
{
    HookEvent("post_inventory_application", PostInventoryApplication);

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
            if(IsPlayerAlive(i))
                TF2_AddCondition(i, TFCond_Kritzkrieged, TFCondDuration_Infinite);
        }
    }
}

void DisableMedieval()
{
    GameRules_SetProp("m_bPlayingMedieval", 0);
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i)){
            if(TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged))
                TF2_RemoveCondition(i, TFCond_Kritzkrieged);
            int health = GetClientHealth(i);
            TF2_RemoveAllWeapons(i);
            TF2_RegeneratePlayer(i);
            SetEntityHealth(i, health < 1 ? 1 : health);
        }
    }
}

public void PostInventoryApplication(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;

    TF2_AddCondition(client, TFCond_Kritzkrieged, TFCondDuration_Infinite);
}
