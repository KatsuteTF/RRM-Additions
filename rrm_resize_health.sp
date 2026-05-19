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
ConVar cMin = null;
float gMin = 0.0;
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Health Size Modifier",
    author = "Katsute",
    description = "Modifier that resizes players based on their health percentage.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_size_health_min", "0.25", "Minimum size when at 0% health.");

    cMin.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_size_health", "rrm");
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
    RRM_Register("Health Size", 0.0, 0.0, false, RRM_Callback_HealthSize);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    gMin = StringToFloat(newValue);
}

public int RRM_Callback_HealthSize(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        UpdateSize();
        if(gTimer == null)
            gTimer = CreateTimer(0.5, Timer_UpdateSize, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        RemoveSize();
        if(gTimer != null)
        {
            KillTimer(gTimer);
            gTimer = null;
        }
    }
    return gEnabled;
}

public Action Timer_UpdateSize(Handle timer)
{
    if(!gEnabled)
    {
        gTimer = null;
        return Plugin_Stop;
    }
    UpdateSize();
    return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled)
        return Plugin_Continue;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
    return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
    if(!gEnabled)
        return;
    if(IsClientInGame(client) && IsPlayerAlive(client))
        SetPlayerSize(client);
}

void UpdateSize()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i) && IsPlayerAlive(i))
            SetPlayerSize(i);
}

void SetPlayerSize(int client)
{
    int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    if(maxHealth <= 0)
        return;
    float pct = float(GetClientHealth(client)) / float(maxHealth);
    if(pct > 1.0) pct = 1.0;
    if(pct < 0.0) pct = 0.0;
    float newSize = gMin + (1.0 - gMin) * pct;

    float currentSize = GetEntPropFloat(client, Prop_Send, "m_flModelScale");

    // When growing, verify the larger hull fits before applying
    if(newSize > currentSize)
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);

        // TF2 standing hull scaled to new size; Z min is always 0 (hull anchored at feet)
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
            // Try lifting the player by the extra height so ground-level
            // geometry (slopes, steps) no longer blocks the wider hull
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
            // Still blocked (e.g. ceiling) — skip resize this tick
            return;
        }
    }

    SetEntPropFloat(client, Prop_Send, "m_flModelScale", newSize);
}

public bool TraceFilter_IgnoreClient(int entity, int contentsMask, any data)
{
    return entity != data;
}

void RemoveSize()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i))
            SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
}
