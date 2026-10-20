#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name        = "Wh1Tes Dense Smoke",
	author      = "Server Owner",
	description = "Adds an extra smoke stack at each smoke grenade detonation",
	version     = "1.0.0",
	url         = ""
};

public void OnPluginStart()
{
	HookEvent("smokegrenade_detonate", Event_Detonate);
}

public void Event_Detonate(Event event, const char[] name, bool dontBroadcast)
{
	float pos[3];
	pos[0] = event.GetFloat("x");
	pos[1] = event.GetFloat("y");
	pos[2] = event.GetFloat("z") + 8.0;

	int ent = CreateEntityByName("env_smokestack");
	if (ent == -1)
		return;

	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(ent, "BaseSpread", "30");
	DispatchKeyValue(ent, "SpreadSpeed", "15");
	DispatchKeyValue(ent, "Speed", "10");
	DispatchKeyValue(ent, "StartSize", "70");
	DispatchKeyValue(ent, "EndSize", "170");
	DispatchKeyValue(ent, "Rate", "45");
	DispatchKeyValue(ent, "JetLength", "55");
	DispatchKeyValue(ent, "SmokeMaterial", "particle/particle_smokegrenade.vmt");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "TurnOn");
	CreateTimer(19.0, Timer_Kill, EntIndexToEntRef(ent));
}

public Action Timer_Kill(Handle timer, int ref)
{
	int ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "TurnOff");
		AcceptEntityInput(ent, "Kill");
	}
	return Plugin_Stop;
}
