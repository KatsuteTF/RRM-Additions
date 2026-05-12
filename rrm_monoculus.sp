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
float gChance = 0.0;
ConVar cMin = null, cMax = null, cDuration = null;
float gMin = 0.0, gMax = 0.0, gDuration = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Monoculus Modifier",
    author = "Katsute",
    description = "Modifier that spawns a monoculus on death.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_monoculus_min",      "0.1",  "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_monoculus_max",      "1.0",  "Maximum value for the random number generator.");
    cDuration = CreateConVar("rrm_monoculus_duration", "30.0", "Duration for the monoculus to exist.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDuration.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gDuration = cDuration.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_monoculus", "rrm");

    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Monoculus", gMin, gMax, false, RRM_Callback_Monoculus);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cMin)
        gMin = fNewValue;
    else if(convar == cMax)
        gMax = fNewValue;
    else if(convar == cDuration)
        gDuration = fNewValue;
}

public int RRM_Callback_Monoculus(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client   = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(client == attacker)
        return;
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return;

    float origin[3];
    GetClientAbsOrigin(client, origin);
    float angles[3] = {0.0, 0.0, 0.0};

    if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
    {
        int ent = CreateEntityByName("eyeball_boss");
        if(ent == -1)
            return;

        SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(attacker));

        DispatchSpawn(ent);
        TeleportEntity(ent, origin, angles, NULL_VECTOR);
        ActivateEntity(ent);

        CreateTimer(gDuration, OnBossDuration, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action OnBossDuration(const Handle timer, const int entref)
{
    int ent = EntRefToEntIndex(entref);
    if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Continue;
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
