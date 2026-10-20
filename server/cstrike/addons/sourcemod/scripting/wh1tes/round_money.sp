#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name        = "Wh1Tes Round Money",
	author      = "Server Owner",
	description = "Classic rules: max money each round, no freeze time",
	version     = "1.1.0",
	url         = ""
};

ConVar g_Cvar;

public void OnPluginStart()
{
	g_Cvar = CreateConVar("wh1tes_maxmoney", "1", "Refill all players to 16000 at spawn");
	AutoExecConfig(true, "round_money");
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("round_start", Event_RoundStart);
}

void ApplyClassic()
{
	ConVar fz = FindConVar("mp_freezetime");
	if (fz != null)
		fz.SetInt(0);
	ConVar sm = FindConVar("mp_startmoney");
	if (sm != null)
		sm.SetInt(16000);
}

public void OnMapStart()
{
	ApplyClassic();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ApplyClassic();
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_Cvar == null || !g_Cvar.BoolValue)
		return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client))
		CreateTimer(0.2, Timer_Money, GetClientSerial(client));
}

public Action Timer_Money(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (client > 0 && IsClientInGame(client))
		SetEntProp(client, Prop_Send, "m_iAccount", 16000);
	return Plugin_Stop;
}
