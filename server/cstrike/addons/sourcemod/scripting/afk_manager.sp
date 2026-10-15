/*
 * Simple AFK Manager for CS:S v34
 *
 * Warns idle players, then moves them to spectator so slots stay free.
 * Activity = pressing buttons or changing position.
 *
 * ConVars (cfg/sourcemod/afk_manager.cfg):
 *   sm_afk_enabled  "1"    - master switch
 *   sm_afk_warn     "90"   - seconds idle before warning
 *   sm_afk_move     "180"  - seconds idle before moving to spectator
 *
 * Install: compile -> afk_manager.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvEnabled;
ConVar g_cvWarn;
ConVar g_cvMove;

float g_fLastAction[MAXPLAYERS + 1];
float g_fPos[MAXPLAYERS + 1][3];
bool  g_bWarned[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "Simple AFK Manager",
    author      = "Server Owner",
    description = "Warns and moves AFK players to spectator",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvEnabled = CreateConVar("sm_afk_enabled", "1", "Enable AFK manager", _, true, 0.0, true, 1.0);
    g_cvWarn    = CreateConVar("sm_afk_warn", "90", "Seconds idle before warning", _, true, 10.0);
    g_cvMove    = CreateConVar("sm_afk_move", "180", "Seconds idle before moving to spectator", _, true, 30.0);
    AutoExecConfig(true, "afk_manager");
    CreateTimer(5.0, Timer_CheckAFK, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
    Touch(client);
    g_bWarned[client] = false;
}

void Touch(int client)
{
    g_fLastAction[client] = GetGameTime();
    g_bWarned[client] = false;
    if (IsClientInGame(client))
        GetClientAbsOrigin(client, g_fPos[client]);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;
    if (buttons != 0)
        Touch(client);
    return Plugin_Continue;
}

public Action Timer_CheckAFK(Handle timer)
{
    if (!g_cvEnabled.BoolValue)
        return Plugin_Continue;

    float now = GetGameTime();
    float warnAfter = g_cvWarn.FloatValue;
    float moveAfter = g_cvMove.FloatValue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        int team = GetClientTeam(i);
        if (team < 2) // only check T/CT players
            continue;

        // moved since last check?
        float pos[3];
        GetClientAbsOrigin(i, pos);
        if (GetVectorDistance(pos, g_fPos[i]) > 12.0)
        {
            Touch(i);
            continue;
        }

        float idle = now - g_fLastAction[i];
        if (idle >= moveAfter)
        {
            ChangeClientTeam(i, 1);
            PrintToChatAll("\x04💤 %N \x01به‌خاطر AFK بودن به تماشاگر منتقل شد", i);
            Touch(i);
        }
        else if (idle >= warnAfter && !g_bWarned[i])
        {
            g_bWarned[i] = true;
            PrintToChat(i, "\x02⚠️ AFK هستی! \x01تا %d ثانیه‌ی دیگه تکون نخوری میری تماشاگر",
                RoundToNearest(moveAfter - idle));
        }
    }
    return Plugin_Continue;
}
