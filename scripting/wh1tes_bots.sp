#include <sourcemod>

// Wh1Tes Bots — Ali's rule (2026-10-23): bots exist ONLY to keep a
// lone player company. Exactly 1 real player in game -> 4 bots.
// 0 players, or 2+ real players -> no bots at all (at night ~10
// friends play and leftover bots are just annoying).
// Enforced by driving bot_quota (0/4) + bot_kick, re-checked on every
// join/leave and round start.

public Plugin myinfo =
{
    name = "Wh1Tes Bots",
    author = "Wh1Tes",
    description = "4 bots only while exactly 1 real player is in game",
    version = "1.1.0",
    url = ""
};

ConVar g_cvQuota;
ConVar g_cvMode;
ConVar g_cvJoinAfter;
ConVar g_cvManual;

public void OnPluginStart()
{
    g_cvQuota = FindConVar("bot_quota");
    g_cvMode = FindConVar("bot_quota_mode");
    g_cvJoinAfter = FindConVar("bot_join_after_player");
    g_cvManual = CreateConVar("wh1tes_bots_manual", "-1", "Manual bot target set by the admin panel (-1 = auto)");
    if (g_cvMode != null)
        g_cvMode.SetString("normal");
    if (g_cvJoinAfter != null)
        g_cvJoinAfter.SetInt(1);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    Enforce();
}

public void OnMapStart()
{
    Enforce();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    Enforce();
}

public void OnClientPutInServer(int client)
{
    // Bots joining/leaving never change the human count, so don't
    // bother re-scheduling a check for them.
    if (IsFakeClient(client))
        return;
    CreateTimer(1.0, Timer_Enforce, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client))
        return;
    CreateTimer(1.0, Timer_Enforce, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Enforce(Handle timer)
{
    Enforce();
    return Plugin_Stop;
}

void Enforce()
{
    if (g_cvQuota == null)
        return;
    int humans = 0;
    bool botsPresent = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        if (IsFakeClient(i))
            botsPresent = true;
        else
            humans++;
    }
    if (humans == 1)
    {
        // Manual target from the admin panel wins; default is 4.
        // The panel fully controls this value (including lowering it),
        // this plugin just applies whatever target is currently set.
        int target = 4;
        if (g_cvManual != null && g_cvManual.IntValue >= 0)
            target = g_cvManual.IntValue;
        if (g_cvQuota.IntValue != target)
        {
            g_cvQuota.SetInt(target);
            PrintToServer("[bots] 1 human -> bot_quota %d", target);
        }
    }
    else
    {
        // Friends-night rule stands: no bots with 0 or 2+ humans.
        // A manual target is cleared so leaving friends restores auto 4.
        if (g_cvManual != null && g_cvManual.IntValue != -1)
            g_cvManual.SetInt(-1);
        if (g_cvQuota.IntValue != 0)
        {
            g_cvQuota.SetInt(0);
            PrintToServer("[bots] %d humans -> bot_quota 0", humans);
        }
        if (botsPresent)
            ServerCommand("bot_kick");
    }
}
