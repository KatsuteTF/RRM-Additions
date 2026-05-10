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

public void OnMapStart()
{
    PrecacheModel("models/buildables/sentry1.mdl", true);
    PrecacheModel("models/buildables/sentry2.mdl", true);
    PrecacheModel("models/buildables/sentry3.mdl", true);
    PrecacheModel("models/buildables/dispenser.mdl", true);
    PrecacheModel("models/buildables/dispenser2.mdl", true);
    PrecacheModel("models/buildables/dispenser3.mdl", true);
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
    bool isSentry = (GetRandomInt(0, 1) == 0);
    int level = GetRandomInt(1, 3);

    char model[PLATFORM_MAX_PATH];
    if(isSentry)
        Format(model, sizeof(model), "models/buildables/sentry%d.mdl", level);
    else if(level == 1)
        strcopy(model, sizeof(model), "models/buildables/dispenser.mdl");
    else
        Format(model, sizeof(model), "models/buildables/dispenser%d.mdl", level);

    int ent = CreateEntityByName("prop_dynamic");
    if(ent == -1)
        return;

    DispatchKeyValue(ent, "model", model);
    DispatchKeyValue(ent, "solid", "0");

    float origin[3];
    GetClientAbsOrigin(client, origin);
    float angles[3] = {0.0, 0.0, 0.0};

    DispatchSpawn(ent);
    TeleportEntity(ent, origin, angles, NULL_VECTOR);

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
