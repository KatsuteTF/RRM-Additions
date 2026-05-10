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
ConVar cMin = null, cMax = null, cDistance = null, cDuration = null;
float gMin = 0.0, gMax = 0.0, gDistance = 0.0, gDuration = 0.0;

float gLastPos[MAXPLAYERS + 1][3];
float gDistAccum[MAXPLAYERS + 1];
bool gInit[MAXPLAYERS + 1];
Handle gTimer = null;

public Plugin myinfo =
{
    name = "[RRM] Crit Move Modifier",
    author = "Katsute",
    description = "Modifier that grants crits as players move.",
    version = "1.0"
};

public void OnPluginStart()
{
    cMin      = CreateConVar("rrm_crit_move_min",      "0.1",   "Minimum value for the random number generator.");
    cMax      = CreateConVar("rrm_crit_move_max",      "1.0",   "Maximum value for the random number generator.");
    cDistance = CreateConVar("rrm_crit_move_distance", "500.0", "Distance to travel before triggering crits.");
    cDuration = CreateConVar("rrm_crit_move_duration", "3.0",   "Duration for crits per trigger.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cDistance.AddChangeHook(OnConvarChanged);
    cDuration.AddChangeHook(OnConvarChanged);

    gMin      = cMin.FloatValue;
    gMax      = cMax.FloatValue;
    gDistance = cDistance.FloatValue;
    gDuration = cDuration.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_crit_move", "rrm");
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Crit Move", gMin, gMax, false, RRM_Callback_CritMove);
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
    else if(convar == cDuration)
        gDuration = StringToFloat(newValue);
}

public int RRM_Callback_CritMove(bool enable, float value)
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
            if(IsClientInGame(i) && TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged))
                TF2_RemoveCondition(i, TFCond_Kritzkrieged);
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
                TF2_AddCondition(i, TFCond_Kritzkrieged, gDuration);
        }
    }
    return Plugin_Continue;
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}
