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
float gDur = 0.0;
ConVar cDur = null, cDelay = null;
float gDelay = 0.0;

public Plugin myinfo = {
    name = "[RRM] critter Modifier",
    author = "Katsute",
    description = "Modifier that forces crit on kill.",
    version = "1.0"
};

public void OnPluginStart(){
    cDelay = CreateConVar("rrm_attribute_crit_delay", "1.2", "Delay to apply attribute.");
    cDur = CreateConVar("rrm_attribute_crit_duration", "5", "How long to have crits.");

    cDelay.AddChangeHook(OnConvarChanged);
    cDur.AddChangeHook(OnConvarChanged);

    gDelay = cDelay.FloatValue;
    gDur = cDur.FloatValue;

    HookEvent("post_inventory_application", PostInventoryApplication);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_attribute_crit", "rrm");
}

public int RRM_OnRegOpen(){
    RegisterModifiers();
}

void RegisterModifiers(){
    RRM_Register("Crit on Kill", 0.0, 0.0, false, RRM_Callback_Attribute);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue){
    if (StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cDelay)
        gDelay = fNewValue;
    else if(convar == cDur)
        gDur = fNewValue;
}

public int RRM_Callback_Attribute(bool enable, float value){
    gEnabled = enable;

    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i)){
            int health = GetClientHealth(i);
            TF2_RemoveAllWeapons(i);
            TF2_RegeneratePlayer(i);
            SetEntityHealth(i, health < 1 ? 1 : health);
        }
    }
    return gEnabled;
}

public void PostInventoryApplication(const Handle event, const char[] name, const bool dontBroadcast){
    if(gEnabled){
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        CreateTimer(gDelay, PostInventoryApplicationDelayed, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action PostInventoryApplicationDelayed(const Handle timer, const int client){
    if(gEnabled && IsClientInGame(client)){
        int primary   = GetPlayerWeaponSlot(client, 0);
        int secondary = GetPlayerWeaponSlot(client, 1);
        int melee     = GetPlayerWeaponSlot(client, 2);

        if(primary != -1 && TF2Attrib_GetByDefIndex(primary, 2050) == Address_Null){
            ApplyPrimary(primary);
            TF2Attrib_SetByDefIndex(primary, 2050, 1.0);
        }
        if(secondary != -1 && TF2Attrib_GetByDefIndex(secondary, 2050) == Address_Null){
            ApplySecondary(secondary);
            TF2Attrib_SetByDefIndex(secondary, 2050, 1.0);
        }
        if(melee != -1 && TF2Attrib_GetByDefIndex(melee, 2050) == Address_Null){
            ApplyMelee(melee);
            TF2Attrib_SetByDefIndex(melee, 2050, 1.0);
        }
    }
    return Plugin_Continue;
}

public void ApplyAttribute(const int ent, const int attribute, const float value){
    if(ent != -1 && IsValidEntity(ent)){
        Address addr = TF2Attrib_GetByDefIndex(ent, attribute);
        float current = addr != Address_Null ? TF2Attrib_GetValue(addr) : 1.0;
        TF2Attrib_SetByDefIndex(ent, attribute, current * value);
    }
}

public void ApplyPrimary(const int ent){
    ApplyAttribute(ent, 31, gDur);
}

public void ApplySecondary(const int ent){
    ApplyAttribute(ent, 31, gDur);
}

public void ApplyMelee(const int ent){
    ApplyAttribute(ent, 31, gDur);
}