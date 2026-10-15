/*
 * Damage Display for CS:S v34
 * Shows the attacker how much damage they dealt (hint text, not chat spam).
 *
 * Player command: !dmg  (toggle for yourself)
 *
 * Install: compile -> damage_display.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvEnabled;
bool   g_bDmg[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "Damage Display",
    author      = "Server Owner",
    description = "Shows damage dealt to the attacker",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvEnabled = CreateConVar("sm_dmg_enabled", "1", "Enable damage display", _, true, 0.0, true, 1.0);
    RegConsoleCmd("sm_dmg", Cmd_Toggle, "Toggle damage display for yourself");
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    AutoExecConfig(true, "damage_display");
}

public void OnClientPutInServer(int client)
{
    g_bDmg[client] = true;
}

public Action Cmd_Toggle(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    g_bDmg[client] = !g_bDmg[client];
    PrintToChat(client, "🎯 نمایش دمیج: %s", g_bDmg[client] ? "روشن ✅" : "خاموش ❌");
    return Plugin_Handled;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnabled.BoolValue)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));

    if (attacker < 1 || attacker > MaxClients || attacker == victim
        || !IsClientInGame(attacker) || IsFakeClient(attacker) || !g_bDmg[attacker])
        return;

    int dmg = event.GetInt("dmg_health");
    int hp  = event.GetInt("health"); // victim hp after damage
    if (hp < 0)
        hp = 0;

    PrintHintText(attacker, "🎯 Damage: %d  |  HP: %d", dmg, hp);
}
