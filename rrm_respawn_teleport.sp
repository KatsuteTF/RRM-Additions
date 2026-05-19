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
float gRoundStartTime = -1.0;
ConVar cCount = null;
int gCount = 3;

public Plugin myinfo =
{
    name = "[RRM] Respawn Teleport Modifier",
    author = "Katsute",
    description = "Modifier that teleports players to a random furthest alive teammate from spawn on respawn.",
    version = "1.0"
};

public void OnPluginStart()
{
    cCount = CreateConVar("rrm_respawn_teleport_count", "3", "Number of furthest teammates to randomly select from.");

    cCount.AddChangeHook(OnConvarChanged);

    gCount = cCount.IntValue;

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("teamplay_round_start", OnRoundStart);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_respawn_teleport", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Respawn Teleport", 0.0, 0.0, false, RRM_Callback_SpawnTeleport);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    if(convar == cCount)
        gCount = StringToInt(newValue);
}

public int RRM_Callback_SpawnTeleport(bool enable, float value)
{
    gEnabled = enable;
    return gEnabled;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    gRoundStartTime = GetGameTime();
    return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled || gRoundStartTime < 0.0 || GetGameTime() - gRoundStartTime < 10.0)
        return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return Plugin_Continue;

    float spawnPos[3];
    GetClientAbsOrigin(client, spawnPos);

    int team = GetClientTeam(client);

    // Collect all eligible teammates with their distances
    int candidates[MAXPLAYERS + 1];
    float candidateDists[MAXPLAYERS + 1];
    int candidateCount = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(i == client)
            continue;
        if(!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;
        if(GetClientTeam(i) != team)
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);

        candidates[candidateCount] = i;
        candidateDists[candidateCount] = GetVectorDistance(spawnPos, pos);
        candidateCount++;
    }

    if(candidateCount == 0)
        return Plugin_Continue;

    // Sort descending by distance (furthest first)
    for(int i = 0; i < candidateCount - 1; i++)
    {
        for(int j = 0; j < candidateCount - i - 1; j++)
        {
            if(candidateDists[j] < candidateDists[j + 1])
            {
                float tmpF = candidateDists[j];
                candidateDists[j] = candidateDists[j + 1];
                candidateDists[j + 1] = tmpF;

                int tmpI = candidates[j];
                candidates[j] = candidates[j + 1];
                candidates[j + 1] = tmpI;
            }
        }
    }

    // Pick randomly from top min(gCount, candidateCount) furthest players
    int pool = (gCount < candidateCount) ? gCount : candidateCount;
    int chosen = candidates[GetURandomInt() % pool];

    float targetPos[3];
    GetClientAbsOrigin(chosen, targetPos);
    TeleportEntity(client, targetPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}
