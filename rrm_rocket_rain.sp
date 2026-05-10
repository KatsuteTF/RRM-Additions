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
ConVar cMin = null, cMax = null, cInterval = null, cCount = null;
float gMin = 0.0, gMax = 0.0, gInterval = 0.0;
int gCount = 0;
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Rocket Rain Modifier",
    author = "Katsute",
    description = "Modifier that rains rockets around players.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_rocket_rain_min",      "0.1", "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_rocket_rain_max",      "1.0", "Maximum value for the random number generator.");
    cInterval = CreateConVar("rrm_rocket_rain_interval", "3.0", "Seconds between rocket rain checks.");
    cCount    = CreateConVar("rrm_rocket_rain_count",    "3",   "Number of rockets to spawn per trigger.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cInterval.AddChangeHook(OnConvarChanged);
    cCount.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gInterval = cInterval.FloatValue;
    gCount    = cCount.IntValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_rocket_rain", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Rocket Rain", gMin, gMax, false, RRM_Callback_RocketRain);
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
    else if(convar == cCount)
        gCount = StringToInt(newValue);
}

public int RRM_Callback_RocketRain(bool enable, float value)
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
            for(int c = 0; c < gCount; c++)
                SpawnRocketAbove(i);
        }
    }
    return Plugin_Continue;
}

void SpawnRocketAbove(int client)
{
    float origin[3];
    GetClientAbsOrigin(client, origin);

    float radius = 150.0;
    float angle  = GetURandomFloat() * 6.283185;

    float pos[3];
    pos[0] = origin[0] + Cosine(angle) * radius;
    pos[1] = origin[1] + Sine(angle)   * radius;
    pos[2] = origin[2] + 400.0;

    float ang[3];
    ang[0] = 90.0;
    ang[1] = 0.0;
    ang[2] = 0.0;

    float vel[3];
    vel[2] = -1100.0;

    int rocket = CreateEntityByName("tf_projectile_rocket");
    if(rocket == -1)
        return;

    SetEntProp(rocket, Prop_Send, "m_iTeamNum", 0);

    DispatchSpawn(rocket);
    TeleportEntity(rocket, pos, ang, vel);
    ActivateEntity(rocket);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
