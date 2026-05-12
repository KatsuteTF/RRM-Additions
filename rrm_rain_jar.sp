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
ConVar cMin = null, cMax = null, cInterval = null;
float gMin = 0.0, gMax = 0.0, gInterval = 0.0;
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Jar Rain Modifier",
    author = "Katsute",
    description = "Modifier that rains jarate and mad milk around players.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_rain_jar_min",      "0.1", "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_rain_jar_max",      "0.5", "Maximum value for the random number generator.");
    cInterval = CreateConVar("rrm_rain_jar_interval", "10.0", "Seconds between jar rain checks.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cInterval.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gInterval = cInterval.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_rain_jar", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Jar Rain", gMin, gMax, false, RRM_Callback_JarRain);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    if(convar == cMin)
        gMin = StringToFloat(newValue);
    else if(convar == cMax)
        gMax = StringToFloat(newValue);
    else if(convar == cInterval)
    {
        gInterval = StringToFloat(newValue);
        if(gEnabled)
            RestartTimer();
    }
}

public int RRM_Callback_JarRain(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        gChance = value;
        RestartTimer();
    }
    else
    {
        if(gTimer != null)
        {
            KillTimer(gTimer);
            gTimer = null;
        }
    }
    return gEnabled;
}

void RestartTimer()
{
    if(gTimer != null)
        KillTimer(gTimer);
    gTimer = CreateTimer(gInterval, TimerTick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerTick(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;
        if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
        {
            SpawnJarAbove(i);
        }
    }
    return Plugin_Continue;
}

void SpawnJarAbove(int client)
{
    float origin[3];
    GetClientAbsOrigin(client, origin);

    float radius = 150.0;
    float angle  = GetURandomFloat() * 6.283185;

    float pos[3];
    pos[0] = origin[0] + Cosine(angle) * radius;
    pos[1] = origin[1] + Sine(angle)   * radius;
    pos[2] = origin[2] + 400.0;

    float vel[3];
    vel[2] = -600.0;

    char classname[32];
    switch(GetURandomInt() % 3)
    {
        case 0: strcopy(classname, sizeof(classname), "tf_projectile_jar");
        case 1: strcopy(classname, sizeof(classname), "tf_projectile_jar_milk");
        case 2: strcopy(classname, sizeof(classname), "tf_projectile_jar_gas");
    }

    int jar = CreateEntityByName(classname);
    if(jar == -1)
        return;

    SetEntProp(jar, Prop_Send, "m_iTeamNum", 0);

    DispatchSpawn(jar);
    TeleportEntity(jar, pos, NULL_VECTOR, vel);
    ActivateEntity(jar);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}