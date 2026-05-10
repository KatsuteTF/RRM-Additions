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
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

#define ENERGY_BALL_SPEED 1100.0

public Plugin myinfo =
{
    name = "[RRM] Energy Ball Shot Modifier",
    author = "Katsute",
    description = "Modifier that randomly replaces shots with Short Circuit energy balls.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_energy_ball_shot_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_energy_ball_shot_max", "1.0", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_energy_ball_shot", "rrm");

    HookEvent("weapon_fire", OnWeaponFire);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Energy Ball Shot", gMin, gMax, false, RRM_Callback_EnergyBallShot);
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

public int RRM_Callback_EnergyBallShot(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public void OnWeaponFire(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
        SpawnEnergyBall(client);
}

void SpawnEnergyBall(int client)
{
    float pos[3], ang[3];
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);

    float fwd[3];
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);

    float vel[3];
    vel[0] = fwd[0] * ENERGY_BALL_SPEED;
    vel[1] = fwd[1] * ENERGY_BALL_SPEED;
    vel[2] = fwd[2] * ENERGY_BALL_SPEED;

    int ball = CreateEntityByName("tf_projectile_energy_ball");
    if(ball == -1)
        return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(weapon != -1)
        SetEntPropEnt(ball, Prop_Send, "m_hLauncher", weapon);

    SetEntPropEnt(ball, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(ball, Prop_Send, "m_iTeamNum", GetClientTeam(client));

    DispatchSpawn(ball);
    TeleportEntity(ball, pos, ang, vel);
    ActivateEntity(ball);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
