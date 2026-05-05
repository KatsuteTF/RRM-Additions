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
int gPlayerBuilding[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

public Plugin myinfo =
{
    name = "[RRM] Building Heads Modifier",
    author = "Katsute",
    description = "Modifier that attaches a random building to each player's head.",
    version = "1.0"
};

public void OnPluginStart()
{
    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_building_heads", "rrm");

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
}

public void OnPluginEnd()
{
    RemoveAllBuildings();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Building Heads", 0.0, 0.0, false, RRM_Callback_BuildingHeads);
}

public int RRM_Callback_BuildingHeads(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        for(int i = 1; i <= MaxClients; i++)
            if(IsClientInGame(i) && IsPlayerAlive(i))
                AttachBuilding(i);
    }
    else
        RemoveAllBuildings();
    return gEnabled;
}

public void OnPlayerSpawn(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
    {
        DetachBuilding(client);
        AttachBuilding(client);
    }
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client <= MaxClients && IsClientInGame(client))
        DetachBuilding(client);
}

void AttachBuilding(int client)
{
    // randomly pick sentry (0) or dispenser (1)
    bool isSentry = (GetURandomInt() % 2 == 0);
    char classname[32];
    if(isSentry)
        strcopy(classname, sizeof(classname), "obj_sentrygun");
    else
        strcopy(classname, sizeof(classname), "obj_dispenser");

    int ent = CreateEntityByName(classname);
    if(ent == -1)
        return;

    SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntProp(ent, Prop_Send, "m_hBuilder", client);
    SetEntProp(ent, Prop_Send, "m_bMiniBuilding", 1);

    float origin[3];
    GetClientAbsOrigin(client, origin);
    float angles[3] = {0.0, 0.0, 0.0};

    DispatchSpawn(ent);
    TeleportEntity(ent, origin, angles, NULL_VECTOR);
    ActivateEntity(ent);

    // parent to player head
    SetVariantString("!activator");
    AcceptEntityInput(ent, "SetParent", client, ent);
    SetVariantString("head");
    AcceptEntityInput(ent, "SetParentAttachment", client, ent);

    gPlayerBuilding[client] = EntIndexToEntRef(ent);
}

void DetachBuilding(int client)
{
    int entref = gPlayerBuilding[client];
    if(entref == INVALID_ENT_REFERENCE)
        return;
    int ent = EntRefToEntIndex(entref);
    if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    gPlayerBuilding[client] = INVALID_ENT_REFERENCE;
}

void RemoveAllBuildings()
{
    for(int i = 1; i <= MaxClients; i++)
        DetachBuilding(i);
}
