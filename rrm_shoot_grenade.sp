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

#define GRENADE_SPEED 960.0

public Plugin myinfo =
{
    name = "[RRM] Grenade Shot Modifier",
    author = "Katsute",
    description = "Modifier that randomly replaces shots with grenades.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_shoot_grenade_min", "0.01", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_shoot_grenade_max", "0.1", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_shoot_grenade", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Grenade Shot", gMin, gMax, false, RRM_Callback_GrenadeShot);
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

public int RRM_Callback_GrenadeShot(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
    if (!gEnabled)
        return Plugin_Continue;

    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (gChance > RandomFloat(0.0, 1.0))
        SpawnGrenade(client);

    return Plugin_Continue;
}

void SpawnGrenade(int client)
{
    float pos[3], ang[3];
    GetClientEyePosition(client, pos);
    pos[2] += 10.0;
    GetClientEyeAngles(client, ang);

    float fwd[3];
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);

    float vel[3];
    vel[0] = fwd[0] * GRENADE_SPEED;
    vel[1] = fwd[1] * GRENADE_SPEED;
    vel[2] = fwd[2] * GRENADE_SPEED;

    int proj = CreateEntityByName("tf_projectile_pipe");
    if(proj == -1)
        return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(weapon != -1)
        SetEntPropEnt(proj, Prop_Send, "m_hLauncher", weapon);

    SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(proj, Prop_Send, "m_iTeamNum", GetClientTeam(client));

    SetEntPropFloat(proj, Prop_Send, "m_flDamage", 100.0);
    SetEntPropFloat(proj, Prop_Send, "m_DmgRadius", 150.0);

    DispatchSpawn(proj);
    TeleportEntity(proj, pos, ang, vel);
    ActivateEntity(proj);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}