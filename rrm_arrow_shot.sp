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

#define ARROW_SPEED 2400.0

public Plugin myinfo =
{
    name = "[RRM] Arrow Shot Modifier",
    author = "Katsute",
    description = "Modifier that randomly replaces shots with flaming arrows.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin = CreateConVar("rrm_arrow_shot_min", "0.1", "Minimum value for the random number generator.");
    cMax = CreateConVar("rrm_arrow_shot_max", "1.0", "Maximum value for the random number generator.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);

    gMin = cMin.FloatValue;
    gMax = cMax.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_arrow_shot", "rrm");

    HookEvent("weapon_fire", OnWeaponFire);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Arrow Shot", gMin, gMax, false, RRM_Callback_ArrowShot);
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

public int RRM_Callback_ArrowShot(bool enable, float value)
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
        SpawnArrow(client);
}

void SpawnArrow(int client)
{
    float pos[3], ang[3];
    GetClientEyePosition(client, pos);
    GetClientEyeAngles(client, ang);

    float forward[3];
    GetAngleVectors(ang, forward, NULL_VECTOR, NULL_VECTOR);

    float vel[3];
    vel[0] = forward[0] * ARROW_SPEED;
    vel[1] = forward[1] * ARROW_SPEED;
    vel[2] = forward[2] * ARROW_SPEED;

    int arrow = CreateEntityByName("tf_projectile_arrow");
    if(arrow == -1)
        return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(weapon != -1)
        SetEntPropEnt(arrow, Prop_Send, "m_hLauncher", weapon);

    SetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(arrow, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntProp(arrow, Prop_Send, "m_bFlamingArrow", 1);

    DispatchSpawn(arrow);
    TeleportEntity(arrow, pos, ang, vel);
    ActivateEntity(arrow);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
