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
ConVar cMin = null, cMax = null, cDelay = null;
float gMin = 0.0, gMax = 0.0, gDelay = 0.0;

public Plugin myinfo = {
    name = "[RRM] Projectile Speed Modifier",
    author = "Katsute",
    description = "Modifier that modifies projectile speed.",
    version = "1.0"
};

public void OnPluginStart(){
    cMin = CreateConVar("rrm_attribute_projectile_min", "0.2", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_attribute_projectile_max", "4.0", "Maximum value for the random number generator.");
    cDelay = CreateConVar("rrm_attribute_projectile_delay", "1.2", "Delay to apply attribute.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDelay.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;
    gDelay = cDelay.FloatValue;

    HookEvent("post_inventory_application", PostInventoryApplication);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_attribute_projectile", "rrm");
}

public int RRM_OnRegOpen(){
    RegisterModifiers();
}

void RegisterModifiers(){
    RRM_Register("Projectile Speed", gMin, gMax, false, RRM_Callback_Attribute);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue){
    if (StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cMin)
        gMin = fNewValue;
    else if(convar == cMax)
        gMax = fNewValue;
    else if(convar == cDelay)
        gDelay = fNewValue;
}

public int RRM_Callback_Attribute(bool enable, float value){
    gEnabled = enable;
    if(gEnabled)
        gMul = value;
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
    ApplyAttribute(ent, 103, gMul);
}

public void ApplySecondary(const int ent){
    ApplyAttribute(ent, 103, gMul);
}

public void ApplyMelee(const int ent){
    ApplyAttribute(ent, 103, gMul);
}