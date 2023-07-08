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
float gSize = 0.0;
ConVar cMin = null, cMax = null;
float gMin = 0.0, gMax = 0.0;

public Plugin myinfo =
{
	name = "[RRM] Size Modifier",
    author = "Katsute",
    description = "Modifier that resizes players.",
    version = "1.0"
};

public void OnPluginStart()
{
	cMin = CreateConVar("rrm_size_min", "0.25", "Minimum value for the random number generator.");
	cMax = CreateConVar("rrm_size_max", "1.35", "Maximum value for the random number generator.");

	cMin.AddChangeHook(OnConvarChanged);
	cMax.AddChangeHook(OnConvarChanged);

	gMin = cMin.FloatValue;
	gMax = cMax.FloatValue;

    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	if(RRM_IsRegOpen())
		RegisterModifiers();

	AutoExecConfig(true, "rrm_size", "rrm");
}

public void OnPluginEnd()
{
	RemoveSize();
}

public int RRM_OnRegOpen()
{
	RegisterModifiers();
}

void RegisterModifiers()
{
	RRM_Register("Resize", gMin, gMax, false, RRM_Callback_Size);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue)
{
	if (StrEqual(oldValue, newValue, true))
		return;

	float fNewValue = StringToFloat(newValue);

	if(convar == cMin)
		gMin = fNewValue;
	else if(convar == cMax)
		gMax = fNewValue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!gEnabled)
		return Plugin_Continue;
	int i = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(i, Prop_Send, "m_flModelScale", gSize);
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int i)
{
	if(!gEnabled)
		return;
    SetEntPropFloat(i, Prop_Send, "m_flModelScale", gSize);
}

public int RRM_Callback_Size(bool enable, float value)
{
	gEnabled = enable;
	if(gEnabled)
	{
		gSize = value;
		SetSize();
	}
	else
		RemoveSize();
	return gEnabled;
}

void SetSize()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
        SetEntPropFloat(i, Prop_Send, "m_flModelScale", gSize);
	}
}

void RemoveSize()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
        SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
	}
}