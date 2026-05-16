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
    name = "[RRM] Respawn Teleport Modifier",
    author = "Katsute",
    description = "Modifier that teleports players to the furthest alive teammate from spawn on respawn.",
    version = "1.0"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_spawn_teleport", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Respawn Teleport", 0.0, 0.0, false, RRM_Callback_SpawnTeleport);
}

public int RRM_Callback_SpawnTeleport(bool enable, float value)
{
    gEnabled = enable;
    return gEnabled;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled)
        return Plugin_Continue;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return Plugin_Continue;

    float spawnPos[3];
    GetClientAbsOrigin(client, spawnPos);

    int team = GetClientTeam(client);

    int furthest = -1;
    float furthestDist = -1.0;

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

        float dist = GetVectorDistance(spawnPos, pos);
        if(dist > furthestDist)
        {
            furthestDist = dist;
            furthest = i;
        }
    }

    if(furthest == -1)
        return Plugin_Continue;

    float targetPos[3];
    GetClientAbsOrigin(furthest, targetPos);
    TeleportEntity(client, targetPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}
