// Copyright (C) 2024 Katsute | Licensed under CC BY-NC-SA 4.0

#pragma semicolon 1

#define RRM_VERSION "1.0"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <rrm>

#pragma newdecls required

int gEnabled = 0;
float gChance = 0.0;
ConVar cMin = null, cMax = null, cDistance = null, cHp = null;
float gMin = 0.0, gMax = 0.0, gDistance = 0.0;
int gHp = 0;

float gLastPos[MAXPLAYERS + 1][3];
float gDistAccum[MAXPLAYERS + 1];
bool gInit[MAXPLAYERS + 1];
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Heal Move Modifier",
    author = "Katsute",
    description = "Modifier that heals players as they move.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_heal_move_min",      "0.1",   "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_heal_move_max",      "1.0",   "Maximum value for the random number generator.");
    cDistance = CreateConVar("rrm_heal_move_distance", "500.0", "Distance to travel before triggering healing.");
    cHp       = CreateConVar("rrm_heal_move_hp",       "25",    "HP healed per trigger.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDistance.AddChangeHook(OnConvarChanged);
    cHp.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gDistance = cDistance.FloatValue;
    gHp       = cHp.IntValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_heal_move", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Heal Move", gMin, gMax, false, RRM_Callback_HealMove);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if(StrEqual(oldValue, newValue, true))
        return;

    if(convar == cMin)
        gMin = StringToFloat(newValue);
    else if(convar == cMax)
        gMax = StringToFloat(newValue);
    else if(convar == cDistance)
        gDistance = StringToFloat(newValue);
    else if(convar == cHp)
        gHp = StringToInt(newValue);
}

public int RRM_Callback_HealMove(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
    {
        gChance = value;
        for(int i = 1; i <= MaxClients; i++)
        {
            gDistAccum[i] = 0.0;
            gInit[i] = false;
        }
        if(gTimer == null)
            gTimer = CreateTimer(0.1, TimerTick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        if(gTimer != null)
        {
            KillTimer(gTimer);
            gTimer = null;
        }
        for(int i = 1; i <= MaxClients; i++)
        {
            gDistAccum[i] = 0.0;
            gInit[i] = false;
        }
    }
    return gEnabled;
}

public Action TimerTick(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || !IsPlayerAlive(i))
        {
            gDistAccum[i] = 0.0;
            gInit[i] = false;
            continue;
        }

        float pos[3];
        GetClientAbsOrigin(i, pos);

        if(!gInit[i])
        {
            gLastPos[i][0] = pos[0];
            gLastPos[i][1] = pos[1];
            gLastPos[i][2] = pos[2];
            gInit[i] = true;
            continue;
        }

        float dx = pos[0] - gLastPos[i][0];
        float dy = pos[1] - gLastPos[i][1];
        float dz = pos[2] - gLastPos[i][2];
        float dist = SquareRoot(dx * dx + dy * dy + dz * dz);

        gLastPos[i][0] = pos[0];
        gLastPos[i][1] = pos[1];
        gLastPos[i][2] = pos[2];

        if(gDistance <= 0.0)
            continue;

        gDistAccum[i] += dist;
        if(gDistAccum[i] >= gDistance)
        {
            gDistAccum[i] -= gDistance;
            if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
            {
                int hp    = GetClientHealth(i);
                int maxHp = GetEntProp(i, Prop_Data, "m_iMaxHealth");
                int newHp = hp + gHp;
                if(newHp > maxHp)
                    newHp = maxHp;
                SetEntityHealth(i, newHp);
            }
        }
    }
    return Plugin_Continue;
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
