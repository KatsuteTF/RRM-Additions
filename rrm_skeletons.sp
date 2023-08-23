// Copyright (C) 2023 Katsute | Licensed under CC BY-NC-SA 4.0

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
ConVar cDuration = null;
float gDuration = 0.0;

public Plugin myinfo =
{
    name = "[RRM] Skeleton Modifier",
    author = "Katsute",
    description = "Modifier that spawns skeletons.",
    version = "1.0"
};

public void OnPluginStart()
{
    cDuration = CreateConVar("rrm_skeleton_duration", "30.0", "Duration for skeletons to exist.");

    cDuration.AddChangeHook(OnConvarChanged);

    gDuration = cDuration.FloatValue;

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_skeleton", "rrm");

    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Skeletons", 0.0, 0.0, false, RRM_Callback_Skeletons);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
    if (StrEqual(oldValue, newValue, true))
        return;

    float fNewValue = StringToFloat(newValue);

    if(convar == cDuration)
        gDuration = fNewValue;
}

public int RRM_Callback_Skeletons(bool enable, float value)
{
    gEnabled = enable;
    return gEnabled;
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast){
    if(gEnabled){
        int client   = GetClientOfUserId(GetEventInt(event, "userid"));
        int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

        if(client != attacker && 1 <= client <= MaxClients && IsClientInGame(client) && 1 <= attacker <= MaxClients && IsClientInGame(attacker)){
            float origin[3];
            GetClientAbsOrigin(client, origin);
            float angles[3];
            GetClientAbsAngles(client, angles);
            angles[0] = 0.0;
            angles[2] = 0.0;

            int ent = CreateEntityByName("tf_zombie");

            TeleportEntity(ent, origin, angles, NULL_VECTOR);

            SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
            SetEntProp(ent, Prop_Send, "m_nSkin", GetClientTeam(client) - 2);

            DispatchSpawn(ent);
            CreateTimer(gDuration, OnSkeletonDuration, ent, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action OnSkeletonDuration(const Handle timer, const int ent){
    if(IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Continue;
}