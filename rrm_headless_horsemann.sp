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
ConVar cMin = null, cMax = null, cHealth = null;
float gMin = 0.0, gMax = 0.0;
int gHealth = 0;
ArrayList gSpawned = null;

public Plugin myinfo =
{
    name = "[RRM] Headless Horsemann Modifier",
    author = "Katsute",
    description = "Modifier that spawns a headless horsemann on death.",
    version = "2.0"
};

public void OnPluginStart()
{
    cMin    = CreateConVar("rrm_headless_horsemann_min",    "0.05",  "Minimum value for the random number generator.");
    cMax    = CreateConVar("rrm_headless_horsemann_max",    "0.2",  "Maximum value for the random number generator.");
    cHealth = CreateConVar("rrm_headless_horsemann_health", "400", "Health for the horsemann.");

    cMin.AddChangeHook(OnConvarChanged);
    cMax.AddChangeHook(OnConvarChanged);
    cHealth.AddChangeHook(OnConvarChanged);

    gMin    = cMin.FloatValue;
    gMax    = cMax.FloatValue;
    gHealth = cHealth.IntValue;

    gSpawned = new ArrayList();

    if(RRM_IsRegOpen())
        RegisterModifiers();

    AutoExecConfig(true, "rrm_headless_horsemann", "rrm");

    HookEvent("player_death", OnPlayerDeath);
}

public int RRM_OnRegOpen()
{
    RegisterModifiers();
}

void RegisterModifiers()
{
    RRM_Register("Headless Horsemann on Death", gMin, gMax, false, RRM_Callback_Horseman);
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
    else if(convar == cHealth)
        gHealth = RoundToNearest(fNewValue);
}

public int RRM_Callback_Horseman(bool enable, float value)
{
    gEnabled = enable;
    if(gEnabled)
        gChance = value;
    else
    {
        for(int i = gSpawned.Length - 1; i >= 0; i--)
        {
            int ent = EntRefToEntIndex(gSpawned.Get(i));
            if(ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
                AcceptEntityInput(ent, "Kill");
        }
        gSpawned.Clear();
    }
    return gEnabled;
}

public void OnPlayerDeath(const Handle event, const char[] name, const bool dontBroadcast)
{
    if(!gEnabled)
        return;

    int client   = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(client == attacker)
        return;
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return;
    if(!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
        return;

    float origin[3];
    GetClientAbsOrigin(client, origin);
    float angles[3];
    GetClientAbsAngles(client, angles);
    angles[0] = 0.0;
    angles[2] = 0.0;

    if(gChance > RandomFloat(RandomFloat(0.0, 1.0)))
    {
        int ent = CreateEntityByName("headless_hatman");
        if(ent == -1)
            return;

        SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(attacker));

        DispatchSpawn(ent);
        TeleportEntity(ent, origin, angles, NULL_VECTOR);
        ActivateEntity(ent);

        SetEntProp(ent, Prop_Data, "m_iHealth", gHealth);
        SetEntProp(ent, Prop_Data, "m_iMaxHealth", gHealth);

        gSpawned.Push(EntIndexToEntRef(ent));
    }
}

float RandomFloat(const float min = 0.0, const float max = 1.0){
    return min + GetURandomFloat() * (max - min);
}