#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name        = "Wh1Tes Damage Info",
	author      = "Server Owner",
	description = "Shows the attacker how much HP and armor they dealt",
	version     = "1.2.0",
	url         = ""
};

int g_TotalHP[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_TotalAP[MAXPLAYERS + 1][MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_spawn", Event_Spawn);
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client < 1)
		return;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_TotalHP[client][i] = 0;
		g_TotalAP[client][i] = 0;
		g_TotalHP[i][client] = 0;
		g_TotalAP[i][client] = 0;
	}
}

public void Event_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (victim < 1 || attacker < 1 || attacker == victim)
		return;
	if (!IsClientInGame(attacker) || IsFakeClient(attacker))
		return;

	int dmgHP = event.GetInt("dmg_health");
	int dmgAP = event.GetInt("dmg_armor");
	if (dmgHP <= 0 && dmgAP <= 0)
		return;

	g_TotalHP[attacker][victim] += dmgHP;
	g_TotalAP[attacker][victim] += dmgAP;

	// v1.2.0 — Ali's spec: ONE line only (victim/total line deleted);
	// HP in RED, Armor in BLUE, each with its number. A single HUD
	// text carries one color, so the line is two same-y segments on
	// channels 3/4 with fixed left anchors (HP at x=0.42, Armor at
	// x=0.53) — digit-count changes never move the Armor segment.
	if (dmgHP > 0)
	{
		SetHudTextParams(0.42, 0.40, 1.2, 255, 30, 30, 255, 0, 0.0, 0.0, 0.1);
		ShowHudText(attacker, 3, "-%d HP", dmgHP);
	}
	if (dmgAP > 0)
	{
		SetHudTextParams(0.53, 0.40, 1.2, 60, 130, 255, 255, 0, 0.0, 0.0, 0.1);
		ShowHudText(attacker, 4, "-%d Armor", dmgAP);
	}
}
