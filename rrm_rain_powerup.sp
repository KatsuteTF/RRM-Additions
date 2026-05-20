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

// Rune types for item_powerup_rune matching those used in the other powerup plugins:
// Strength=0, Haste=1, Resist=3, Vampire=4, Plague=5, Precision=6, Agility=7
static const int gRuneTypes[] = {0, 1, 3, 4, 5, 6, 7};

int gEnabled = 0;
float gChance = 0.0;
ConVar cMin = null, cMax = null, cInterval = null;
float gMin = 0.0, gMax = 0.0, gInterval = 0.0;
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Powerup Rain Modifier",
    author = "Katsute",
    description = "Modifier that rains powerups around players.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_rain_powerup_min",      "0.05",  "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_rain_powerup_max",      "0.2",   "Maximum value for the random number generator.");
    cInterval = CreateConVar("rrm_rain_powerup_interval", "10.0",  "Seconds between powerup rain checks.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cInterval.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gInterval = cInterval.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AddCommandListener(OnDropItem, "dropitem");
    AutoExecConfig(true, "rrm_rain_powerup", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Powerup Rain", gMin, gMax, false, RRM_Callback_PowerupRain);
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

public int RRM_Callback_PowerupRain(bool enable, float value)
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
    int ent = -1;
    while((ent = FindEntityByClassname(ent, "item_powerup_rune")) != -1)
    {
        AcceptEntityInput(ent, "Kill");
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;
        if(gChance > RandomFloat(0.0, 1.0))
            SpawnPowerupAbove(i);
    }
    return Plugin_Continue;
}

void SpawnPowerupAbove(int client)
{
    float origin[3];
    GetClientAbsOrigin(client, origin);

    float radius = 150.0;
    float angle  = GetURandomFloat() * (FLOAT_PI * 2.0);

    float pos[3];
    pos[0] = origin[0] + Cosine(angle) * radius;
    pos[1] = origin[1] + Sine(angle)   * radius;
    pos[2] = origin[2];

    int ent = CreateEntityByName("item_powerup_rune");
    if(ent == -1)
        return;

    SetEntProp(ent, Prop_Send, "m_iTeamNum", 0);
    DispatchKeyValueInt(ent, "type", gRuneTypes[GetURandomInt() % sizeof(gRuneTypes)]);

    DispatchSpawn(ent);
    TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
    ActivateEntity(ent);
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}

public Action OnDropItem(const int client, const char[] cmd, const int args){
    if(gEnabled)
        return Plugin_Handled;
    return Plugin_Continue;
}
