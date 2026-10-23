#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes Kill Overlay",
    author = "Wh1Tes",
    description = "Bottom-center kill-streak medal overlay (G7 moder_shop pack)",
    version = "1.3.3"
};

int  g_iStreak[MAXPLAYERS + 1];
int  g_iSerial[MAXPLAYERS + 1];
bool g_bEnabled[MAXPLAYERS + 1];

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    RegConsoleCmd("sm_overlay", Cmd_Overlay, "Toggle the kill-streak overlay for yourself");
    RegServerCmd("sm_overlay_reset", Cmd_OverlayReset, "Re-enable + re-show the kill overlay for everyone in game (diagnostics)");
    // v1.3.1: in Match mode, re-assert the correct overlay state every
    // second. The engine drops r_screenoverlay on its own at times
    // (death/spec transitions — Ali: "it vanished after a few seconds");
    // this makes the medal/band leave ONLY when the game state says so.
    CreateTimer(1.0, Timer_AssertOverlay, _, TIMER_REPEAT);
    for (int i = 1; i <= MaxClients; i++)
        g_bEnabled[i] = true;
}

public void OnMapStart()
{
    char path[PLATFORM_MAX_PATH];
    for (int n = 1; n <= 6; n++)
    {
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay/ct/ct_%d.vtf", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay/ct/ct_%d.vmt", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay/tt/tt_%d.vtf", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay/tt/tt_%d.vmt", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay_m2/ct/ct_%d.vtf", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay_m2/ct/ct_%d.vmt", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay_m2/tt/tt_%d.vtf", n);
        AddFileToDownloadsTable(path);
        Format(path, sizeof(path), "materials/overlays/moder_shop/kill_overlay_m2/tt/tt_%d.vmt", n);
        AddFileToDownloadsTable(path);
    }
    AddFileToDownloadsTable("materials/overlays/moder_shop/score_bg2.vtf");
    AddFileToDownloadsTable("materials/overlays/moder_shop/score_bg2.vmt");
}

public void OnClientPutInServer(int client)
{
    g_iStreak[client] = 0;
    g_iSerial[client] = 0;
    g_bEnabled[client] = true;
}

public Action Cmd_Overlay(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    g_bEnabled[client] = !g_bEnabled[client];
    if (!g_bEnabled[client])
        ClearOverlay(client);
    else if (IsPlayerAlive(client))
        ShowOverlay(client, StageFor(g_iStreak[client]));
    PrintToChat(client, "[Wh1Tes] Kill overlay: %s", g_bEnabled[client] ? "ON" : "OFF");
    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Ali's final word (2026-10-23 18:45): the streak resets EVERY
    // round. (v1.3.2's cross-round persistence was reverted by his
    // direct order.)
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iStreak[i] = 0;
        if (IsClientInGame(i) && !IsFakeClient(i))
            ClearOverlay(i);
    }
    // v1.2.1: on this build player_spawn fires BEFORE round_start, so the
    // spawn-time base medal was wiped by the clear above every round
    // ("overlay completely gone"). Re-show the base stage just after.
    CreateTimer(0.7, Timer_RoundShow, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundShow(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || !g_bEnabled[i])
            continue;
        int team = GetClientTeam(i);
        if (team == 2 || team == 3)
            ShowOverlay(i, StageFor(g_iStreak[i]));
    }
    return Plugin_Stop;
}

public Action Timer_AssertOverlay(Handle timer)
{
    if (!IsMatchMode())
        return Plugin_Continue;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || !g_bEnabled[i])
            continue;
        int team = GetClientTeam(i);
        if ((team == 2 || team == 3) && IsPlayerAlive(i))
            ShowOverlay(i, StageFor(g_iStreak[i]));
        else
            ClearOverlay(i); // match mode: band-only texture
    }
    return Plugin_Continue;
}

public Action Cmd_OverlayReset(int args)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        g_bEnabled[i] = true;
        int team = GetClientTeam(i);
        if (team == 2 || team == 3)
            ShowOverlay(i, StageFor(g_iStreak[i]));
        PrintToServer("[overlay] %N enabled=%d streak=%d team=%d", i, g_bEnabled[i], g_iStreak[i], team);
    }
    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client < 1 || client > MaxClients)
        return;
    if (!IsClientInGame(client) || IsFakeClient(client))
        return;
    int team = GetClientTeam(client);
    if (team != 2 && team != 3)
        return;
    // Ali's call 2026-10-23: the overlay must be on screen from the very
    // start of the round, not only after the first kill. Stage 1 is the
    // base medal (no kill cards yet); kills advance it as before.
    if (g_bEnabled[client])
        ShowOverlay(client, StageFor(g_iStreak[client]));
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim > 0 && victim <= MaxClients)
    {
        g_iStreak[victim] = 0;
        if (IsClientInGame(victim) && !IsFakeClient(victim))
            ClearOverlay(victim);
    }

    if (attacker < 1 || attacker > MaxClients || attacker == victim)
        return;
    if (!IsClientInGame(attacker) || IsFakeClient(attacker))
        return;
    if (victim > 0 && GetClientTeam(attacker) == GetClientTeam(victim))
        return; // no credit for team kills / suicide

    if (g_iStreak[attacker] < 6)
        g_iStreak[attacker]++;

    if (g_bEnabled[attacker])
        ShowOverlay(attacker, StageFor(g_iStreak[attacker]));
}

// Texture numbering vs kills (Ali's report 2026-10-23: "the counter is
// one behind"): texture N shows N-1 kill cards (texture 1 = bare medal,
// texture 6 = full 5-card fan). So the stage for a streak is streak+1,
// capped at 6; a fresh spawn (streak 0) shows the bare medal, texture 1.
int StageFor(int streak)
{
    if (streak < 1)
        return 1;
    int s = streak + 1;
    return s > 6 ? 6 : s;
}

// Match mode (wh1tes_curmode == 1, set by Wh1Tes Modes) uses merged
// medal textures that carry the scoreboard's backdrop band, so the band
// and the medal never fight over the single r_screenoverlay slot.
bool IsMatchMode()
{
    ConVar cv = FindConVar("wh1tes_curmode");
    return cv != null && GetConVarInt(cv) == 1;
}

void ShowOverlay(int client, int stage)
{
    int team = GetClientTeam(client);
    char mat[PLATFORM_MAX_PATH];
    bool match = IsMatchMode();
    if (team == 3)
        Format(mat, sizeof(mat), match
            ? "overlays/moder_shop/kill_overlay_m2/ct/ct_%d"
            : "overlays/moder_shop/kill_overlay/ct/ct_%d", stage);
    else if (team == 2)
        Format(mat, sizeof(mat), match
            ? "overlays/moder_shop/kill_overlay_m2/tt/tt_%d"
            : "overlays/moder_shop/kill_overlay/tt/tt_%d", stage);
    else
        return;

    // Persistent (Ali's call 2026-10-23): the earned stage stays on screen
    // until the player dies or the round ends — no auto-hide timer. The old
    // 2.5s show-then-vanish read as flicker ("هی میره و میاد").
    g_iSerial[client]++;
    ClientCommand(client, "r_screenoverlay \"%s\"", mat);
}

void ClearOverlay(int client)
{
    g_iSerial[client]++;
    // In Match mode the "cleared" state is the band-only texture, so the
    // scoreboard backdrop stays up while dead / between streaks.
    if (IsMatchMode())
        ClientCommand(client, "r_screenoverlay \"overlays/moder_shop/score_bg2\"");
    else
        ClientCommand(client, "r_screenoverlay \"\"");
}
