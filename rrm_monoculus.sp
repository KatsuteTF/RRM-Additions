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
ConVar cDuration = null;
float gDuration = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Monoculus Modifier",
    author = "Katsute",
    description = "Modifier that spawns a monoculus on death.",
    version = "1.0"
};

public void OnPluginStart()
{
    cDuration = CreateConVar("rrm_monoculus_duration", "30.0", "Duration for the monoculus to exist.");

    cDuration.AddChangeHook(OnConvarChanged);

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
    RRM_Register("Monoculus", 0.0, 0.0, false, RRM_Callback_Monoculus);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    if(convar == cDuration)
        gDuration = StringToFloat(newValue);
}

public int RRM_Callback_Monoculus(bool enable, float value)
{
    gEnabled = enable;
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

    int ent = CreateEntityByName("eyeball_boss");
    if(ent == -1)
        return;

    SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(attacker));

    DispatchSpawn(ent);
    TeleportEntity(ent, origin, angles, NULL_VECTOR);
    ActivateEntity(ent);

    CreateTimer(gDuration, OnBossDuration, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnBossDuration(const Handle timer, const int entref)
{
    int ent = EntRefToEntIndex(entref);
    if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Continue;
}
