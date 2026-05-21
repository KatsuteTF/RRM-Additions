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
ConVar cMin = null, cMax = null, cAmount = null;
float gMin = 0.0, gMax = 0.0, gAmount = 0.0;
float gPlayerSize[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[RRM] Grow on Kill Modifier",
    author = "Katsute",
    description = "Modifier that grows players each time they get a kill.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin    = CreateConVar("rrm_size_grow_kill_min",    "0.25",  "Minimum size (starting size) for players.");
    cMax    = CreateConVar("rrm_size_grow_kill_max",    "1.35", "Maximum size a player can grow to.");
    cAmount = CreateConVar("rrm_size_grow_kill_amount", "0.1",  "Amount to grow per kill.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cAmount.AddChangeHook(OnConvarChanged);

    gMin    = cMin.FloatValue;
    gMax    = cMax.FloatValue;
    gAmount = cAmount.FloatValue;

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_size_grow_kill", "rrm");
}

public void OnPluginEnd()
{
    RemoveSize();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
    return 0;
}

void RegisterModifiers()
{
    RRM_Register("Grow on Kill", 0.0, 0.0, false, RRM_Callback_GrowKill);
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
    else if(convar == cAmount)
        gAmount = fNewValue;
}

public int RRM_Callback_GrowKill(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        SetSize();
    else
        RemoveSize();
    return gEnabled;
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
    {
        gPlayerSize[client] = gMin;
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", gMin);
    }
}

public void OnClientPostAdminCheck(int client)
{
    if(!gEnabled)
        return;
    if(IsClientInGame(client))
    {
        gPlayerSize[client] = gMin;
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", gMin);
    }
}

public void OnClientDisconnect(int client)
{
    gPlayerSize[client] = 1.0;
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client   = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(client == attacker)
        return;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
        return;

    float newSize = gPlayerSize[attacker] + gAmount;
    if(newSize > gMax)
        newSize = gMax;

    gPlayerSize[attacker] = newSize;
    ApplySize(attacker, newSize);
}

void SetSize()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        gPlayerSize[i] = gMin;
        SetEntPropFloat(i, Prop_Send, "m_flModelScale", gMin);
    }
}

void RemoveSize()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        gPlayerSize[i] = 1.0;
        SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
    }
}

public bool TraceFilter_IgnoreClient(int entity, int contentsMask, any data)
{
    return entity != data;
}

void ApplySize(int client, float newSize)
{
    float currentSize = GetEntPropFloat(client, Prop_Send, "m_flModelScale");

    if(newSize > currentSize)
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);

        float mins[3], maxs[3];
        mins[0] = -24.0 * newSize;
        mins[1] = -24.0 * newSize;
        mins[2] = 0.0;
        maxs[0] = 24.0 * newSize;
        maxs[1] = 24.0 * newSize;
        maxs[2] = 82.0 * newSize;

        TR_TraceHullFilter(origin, origin, mins, maxs, MASK_PLAYERSOLID, TraceFilter_IgnoreClient, client);

        if(TR_DidHit())
        {
            float liftedOrigin[3];
            liftedOrigin[0] = origin[0];
            liftedOrigin[1] = origin[1];
            liftedOrigin[2] = origin[2] + 82.0 * (newSize - currentSize);

            TR_TraceHullFilter(liftedOrigin, liftedOrigin, mins, maxs, MASK_PLAYERSOLID, TraceFilter_IgnoreClient, client);

            if(!TR_DidHit())
            {
                TeleportEntity(client, liftedOrigin, NULL_VECTOR, NULL_VECTOR);
                SetEntPropFloat(client, Prop_Send, "m_flModelScale", newSize);
            }
            return;
        }
    }

    SetEntPropFloat(client, Prop_Send, "m_flModelScale", newSize);
}
