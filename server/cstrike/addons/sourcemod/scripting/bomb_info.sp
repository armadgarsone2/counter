/*
 * Bomb Info for CS:S v34
 * When the bomb is planted, every alive player sees (updated every second):
 *   💣 time left | distance to bomb (meters) | estimated explosion damage
 *
 * Damage model: C4 does ~500 max damage with ~1024 units (~26m) radius,
 * linear falloff (approximation of the game's radius damage).
 *
 * Install: compile -> bomb_info.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define UNITS_PER_METER 39.37
#define C4_MAX_DAMAGE  500.0
#define C4_RADIUS      1024.0

float g_fPlantTime = 0.0;
float g_fBombPos[3];
bool  g_bPlanted = false;
Handle g_hTimer = null;

public Plugin myinfo =
{
    name        = "Bomb Info",
    author      = "Server Owner",
    description = "Shows C4 countdown, distance and estimated damage",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    HookEvent("bomb_planted",  Event_BombPlanted);
    HookEvent("bomb_defused",  Event_BombEnd);
    HookEvent("bomb_exploded", Event_BombEnd);
    HookEvent("round_end",     Event_BombEnd);
    HookEvent("round_start",   Event_BombEnd);
}

public void Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
    // find the planted c4 to get its position
    int c4 = -1;
    while ((c4 = FindEntityByClassname(c4, "planted_c4")) != -1)
    {
        GetEntPropVector(c4, Prop_Send, "m_vecOrigin", g_fBombPos);
        break;
    }
    g_fPlantTime = GetGameTime();
    g_bPlanted = true;

    if (g_hTimer != null)
        delete g_hTimer;
    g_hTimer = CreateTimer(1.0, Timer_BombInfo, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_BombEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bPlanted = false;
    if (g_hTimer != null)
    {
        delete g_hTimer;
        g_hTimer = null;
    }
}

public Action Timer_BombInfo(Handle timer)
{
    if (!g_bPlanted)
        return Plugin_Stop;

    float c4timer = GetConVarFloat(FindConVar("mp_c4timer"));
    int left = RoundToCeil(c4timer - (GetGameTime() - g_fPlantTime));
    if (left < 0)
        left = 0;

    float vClient[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i))
            continue;

        GetClientAbsOrigin(i, vClient);
        float distUnits = GetVectorDistance(vClient, g_fBombPos);
        float meters = distUnits / UNITS_PER_METER;

        float damage = C4_MAX_DAMAGE * (1.0 - distUnits / C4_RADIUS);
        if (damage < 0.0)
            damage = 0.0;

        if (damage <= 0.0)
            PrintHintText(i, "💣 انفجار تا <font color='#f0a500'>%d</font> ثانیه | فاصله: <font color='#58a6ff'>%.1f</font> متر | ✅ امنی!", left, meters);
        else
            PrintHintText(i, "💣 انفجار تا <font color='#f0a500'>%d</font> ثانیه | فاصله: <font color='#58a6ff'>%.1f</font> متر | 💥 دمیج: <font color='#ff5555'>~%d</font>", left, meters, RoundToNearest(damage));
    }
    return Plugin_Continue;
}
