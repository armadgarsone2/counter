#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name        = "Wh1Tes Damage Info",
	author      = "Server Owner",
	description = "Shows the attacker how much HP and armor they dealt",
	version     = "1.0.0",
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

	char vname[64];
	GetClientName(victim, vname, sizeof(vname));
	int leftHP = event.GetInt("health");

	PrintCenterText(attacker, "-%d HP  -%d Armor  »  %s (HP: %d)  |  Total: %d",
		dmgHP, dmgAP, vname, leftHP, g_TotalHP[attacker][victim]);
}
