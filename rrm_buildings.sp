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
float gChance = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;
int gBuilding[MAXPLAYERS + 1];
int gModel[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[RRM] Buildings Modifier",
    author = "Katsute",
    description = "Modifier that attaches a random leveled building to players on spawn.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_buildings_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_buildings_max", "0.5", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        gBuilding[i] = INVALID_ENT_REFERENCE;
        gModel[i] = INVALID_ENT_REFERENCE;
    }

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_buildings", "rrm");

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath);
}

public void OnMapStart()
{
    PrecacheModel("models/buildables/sentry1.mdl");
    PrecacheModel("models/buildables/sentry2.mdl");
    PrecacheModel("models/buildables/sentry3.mdl");
    PrecacheModel("models/buildables/dispenser.mdl");
    PrecacheModel("models/buildables/dispenser_level2.mdl");
    PrecacheModel("models/buildables/dispenser_level3.mdl");
}

public void OnPluginEnd()
{
    RemoveBuildings();
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Buildings", gMin, gMax, false, RRM_Callback_Buildings);
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
}

public int RRM_Callback_Buildings(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    else
        RemoveBuildings();
    return gEnabled;
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;

    if(gChance > RandomFloat(0.0, 1.0))
        AttachBuilding(client);
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;

    RemovePlayerBuilding(client);
}

public Action Building_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(EntRefToEntIndex(gBuilding[i]) == victim)
        {
            if(IsClientInGame(i) && GetClientTeam(attacker) == GetClientTeam(i))
                return Plugin_Handled;
            break;
        }
    }

    return Plugin_Continue;
}

void GetBuildingModel(bool isSentry, int level, char[] modelPath, int maxlen)
{
    if(isSentry)
    {
        switch(level)
        {
            case 1: strcopy(modelPath, maxlen, "models/buildables/sentry1.mdl");
            case 2: strcopy(modelPath, maxlen, "models/buildables/sentry2.mdl");
            default: strcopy(modelPath, maxlen, "models/buildables/sentry3.mdl");
        }
    }
    else
    {
        switch(level)
        {
            case 1: strcopy(modelPath, maxlen, "models/buildables/dispenser.mdl");
            case 2: strcopy(modelPath, maxlen, "models/buildables/dispenser_level2.mdl");
            default: strcopy(modelPath, maxlen, "models/buildables/dispenser_level3.mdl");
        }
    }
}

void AttachBuilding(int client)
{
    RemovePlayerBuilding(client);

    int level    = GetRandomInt(1, 3);
    bool isSentry = GetRandomInt(0, 1) == 0;

    float origin[3];
    GetClientAbsOrigin(client, origin);
    float angles[3];
    GetClientAbsAngles(client, angles);
    angles[0] = 0.0;
    angles[2] = 0.0;

    int building = CreateEntityByName(isSentry ? "obj_sentrygun" : "obj_dispenser");
    if(building == -1)
        return;

    SetEntProp(building, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntProp(building, Prop_Send, "m_hBuilder", client);
    SetEntProp(building, Prop_Send, "m_iUpgradeLevel", level);
    SetEntProp(building, Prop_Send, "m_iHighestUpgradeLevel", level);

    DispatchSpawn(building);
    TeleportEntity(building, origin, angles, NULL_VECTOR);
    ActivateEntity(building);

    // Prevent players from getting stuck inside the building
    SetEntProp(building, Prop_Data, "m_CollisionGroup", 2); // COLLISION_GROUP_DEBRIS

    // Hide the building entity's own model; the prop_dynamic below handles the visual
    SetEntProp(building, Prop_Send, "m_fEffects", GetEntProp(building, Prop_Send, "m_fEffects") | 32); // EF_NODRAW

    // Parent building to player so it follows them
    SetVariantString("!activator");
    AcceptEntityInput(building, "SetParent", client, building);

    // Block damage from the builder's own team
    SDKHook(building, SDKHook_OnTakeDamage, Building_OnTakeDamage);

    gBuilding[client] = EntIndexToEntRef(building);

    // Create visible model using EF_BONEMERGE so it renders correctly on the player
    char modelPath[PLATFORM_MAX_PATH];
    GetBuildingModel(isSentry, level, modelPath, sizeof(modelPath));

    int model = CreateEntityByName("prop_dynamic");
    if(model == -1)
        return;

    DispatchKeyValue(model, "model", modelPath);
    DispatchKeyValue(model, "solid", "0");
    DispatchKeyValue(model, "disableshadows", "1");
    DispatchSpawn(model);
    ActivateEntity(model);

    // Parent to player
    SetVariantString("!activator");
    AcceptEntityInput(model, "SetParent", client, model);

    // EF_BONEMERGE renders the prop at the parent's root bone (player's feet) without needing TeleportEntity
    SetEntProp(model, Prop_Send, "m_fEffects", GetEntProp(model, Prop_Send, "m_fEffects") | 1); // EF_BONEMERGE

    gModel[client] = EntIndexToEntRef(model);
}

void RemovePlayerBuilding(int client)
{
    int building = EntRefToEntIndex(gBuilding[client]);
    if(building != INVALID_ENT_REFERENCE && IsValidEntity(building))
        AcceptEntityInput(building, "Kill");
    gBuilding[client] = INVALID_ENT_REFERENCE;

    int model = EntRefToEntIndex(gModel[client]);
    if(model != INVALID_ENT_REFERENCE && IsValidEntity(model))
        AcceptEntityInput(model, "Kill");
    gModel[client] = INVALID_ENT_REFERENCE;
}

void RemoveBuildings()
{
    for(int i = 1; i <= MaxClients; i++)
        RemovePlayerBuilding(i);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
