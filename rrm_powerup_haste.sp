// Copyright (C) 2023 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

TFCond cond = TFCond_RuneHaste;

int gEnabled = 0;

public Plugin myinfo = {
    name= "[RRM] Haste Powerup Modifier",
    author = "Katsute",
    description = "Modifier that grants haste powerup.",
    version = "1.0"
};

public void OnPluginStart(){
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AddCommandListener(OnDropItem, "dropitem");

    AutoExecConfig(true, "rrm_powerup_haste", "rrm");
}

public int RRM_OnRegOpen(){
    RegisterModifiers();
}

void RegisterModifiers(){
    RRM_Register("Haste Powerup", 0.0, 0.0, false, RRM_Callback_Powerup);
}

public int RRM_Callback_Powerup(bool enable, float value){
    gEnabled = enable;
    if(gEnabled){
        int ent;
        while((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
            SDKHook(ent, SDKHook_EndTouchPost, OnExitResupply);

        for(int i = 1; i < MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                ApplyPowerup(i);
    }else{
        int ent;
        while((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
            SDKUnhook(ent, SDKHook_EndTouchPost, OnExitResupply);

        for(int i = 1; i < MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                RemovePowerup(i);
    }
    return gEnabled;
}

public void OnEntityCreated(int ent, const char[] classname){
    if(gEnabled && strncmp(classname, "item_power", 10) == 0 && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
}

public void OnExitResupply(const int resupply, const int client){
    if(gEnabled && 0 < client < MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
        ApplyPowerup(client);
}

public Action OnDropItem(const int client, const char[] cmd, any args){
    if(gEnabled)
        return Plugin_Handled;
    return Plugin_Continue;
}

public void ApplyPowerup(const int client){
    if(!TF2_IsPlayerInCondition(client, cond)){
        TF2_AddCondition(client, cond);
        TF2_RegeneratePlayer(client);
    }
}

public void RemovePowerup(const int client){
    if(TF2_IsPlayerInCondition(client, cond))
        TF2_RemoveCondition(client, cond);
}