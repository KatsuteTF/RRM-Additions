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
ConVar cMin = null, cMax = null, cDamage = null, cRadius = null;
float gMin = 0.0, gMax = 0.0, gDamage = 0.0, gRadius = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Explosive Shot Modifier",
    author = "Katsute",
    description = "Modifier that spawns an explosion at the point of impact.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin    = CreateConVar("rrm_explosive_shot_min",    "0.1",   "Minimum value for the random number generator.");
    cMax    = CreateConVar("rrm_explosive_shot_max",    "1.0",   "Maximum value for the random number generator.");
    cDamage = CreateConVar("rrm_explosive_shot_damage", "50.0",  "Explosion damage.");
    cRadius = CreateConVar("rrm_explosive_shot_radius", "150.0", "Explosion radius.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDamage.AddChangeHook(OnConvarChanged);
    cRadius.AddChangeHook(OnConvarChanged);

    gMin    = cMin.FloatValue;
    gMax    = cMax.FloatValue;
    gDamage = cDamage.FloatValue;
    gRadius = cRadius.FloatValue;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
    }

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_explosive_shot", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Explosive Shot", gMin, gMax, false, RRM_Callback_ExplosiveShot);
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
    else if(convar == cDamage)
        gDamage = fNewValue;
    else if(convar == cRadius)
        gRadius = fNewValue;
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public int RRM_Callback_ExplosiveShot(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    return gEnabled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!gEnabled)
        return Plugin_Continue;

    if(!(1 <= victim <= MaxClients) || !IsClientInGame(victim))
        return Plugin_Continue;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if(gChance <= RandomFloat(RandomFloat(0.0, 1.0)))
        return Plugin_Continue;

    SpawnExplosion(damagePosition);
    return Plugin_Continue;
}

void SpawnExplosion(float pos[3])
{
    int ent = CreateEntityByName("env_explosion");
    if(ent == -1)
        return;

    char buf[16];

    FloatToString(gDamage, buf, sizeof(buf));
    DispatchKeyValue(ent, "iMagnitude", buf);

    FloatToString(gRadius, buf, sizeof(buf));
    DispatchKeyValue(ent, "iRadiusMagnitude", buf);

    DispatchSpawn(ent);
    TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(ent, "Explode");
}
