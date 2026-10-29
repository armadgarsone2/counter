#include <sourcemod>
#include <sdktools>

// Wh1Tes G7 Extras — wires the remaining G7 pack sounds (Ali's order:
// "install EVERYTHING from G7"): knife hit sounds (nmc), admin join
// sound, match beeps + thunder on Match activation, end-of-vote at
// match end. Files are the pack's own, already on the server.

public Plugin myinfo =
{
    name = "Wh1Tes G7 Extras",
    author = "Wh1Tes",
    description = "G7 pack sounds: knife hits, admin join, match beeps/thunder, match end",
    version = "1.0.1",
    url = ""
};

char g_sKnife[][] = { "nmc/knife/knife1.mp3", "nmc/knife/knife2.mp3", "nmc/knife/knife3.mp3" };
bool g_bAdminAnnounced[MAXPLAYERS + 1];
int g_iAdminCheckAttempts[MAXPLAYERS + 1];
bool g_bBeepFlip;
ConVar g_cvCurMode;
ConVar g_cvMaxRounds;

#define ADMIN_CHECK_INTERVAL 3.0
#define ADMIN_CHECK_MAX_ATTEMPTS 4 // ~12s total window; covers slower password/IP auth

public void OnPluginStart()
{
    // Full precache list (must match OnMapStart exactly) so a late
    // load (plugin loaded mid-map) doesn't leave half the sounds
    // unprecached until the next map change.
    PrecacheSound("nmc/knife/knife1.mp3", true);
    PrecacheSound("nmc/knife/knife2.mp3", true);
    PrecacheSound("nmc/knife/knife3.mp3", true);
    PrecacheSound("admin_plugin/join_admin.mp3", true);
    PrecacheSound("admin_plugin/actions/endofvote.mp3", true);
    PrecacheSound("match/tbeep1.mp3", true);
    PrecacheSound("match/tbeep2.mp3", true);
    PrecacheSound("match/tlbeep1.mp3", true);
    PrecacheSound("g7/thounder.mp3", true);

    AddFileToDownloadsTable("sound/nmc/knife/knife1.mp3");
    AddFileToDownloadsTable("sound/nmc/knife/knife2.mp3");
    AddFileToDownloadsTable("sound/nmc/knife/knife3.mp3");
    AddFileToDownloadsTable("sound/admin_plugin/join_admin.mp3");
    AddFileToDownloadsTable("sound/admin_plugin/actions/endofvote.mp3");
    AddFileToDownloadsTable("sound/match/tbeep1.mp3");
    AddFileToDownloadsTable("sound/match/tbeep2.mp3");
    AddFileToDownloadsTable("sound/match/tlbeep1.mp3");
    AddFileToDownloadsTable("sound/g7/thounder.mp3");

    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);

    EnsureCurModeConVar();

    // mp_maxrounds is a core game convar, never recreated by a
    // reloadable plugin, so it's safe to cache permanently.
    g_cvMaxRounds = FindConVar("mp_maxrounds");
}

public void OnMapStart()
{
    PrecacheSound("nmc/knife/knife1.mp3", true);
    PrecacheSound("nmc/knife/knife2.mp3", true);
    PrecacheSound("nmc/knife/knife3.mp3", true);
    PrecacheSound("admin_plugin/join_admin.mp3", true);
    PrecacheSound("admin_plugin/actions/endofvote.mp3", true);
    PrecacheSound("match/tbeep1.mp3", true);
    PrecacheSound("match/tbeep2.mp3", true);
    PrecacheSound("match/tlbeep1.mp3", true);
    PrecacheSound("g7/thounder.mp3", true);

    AddFileToDownloadsTable("sound/nmc/knife/knife1.mp3");
    AddFileToDownloadsTable("sound/nmc/knife/knife2.mp3");
    AddFileToDownloadsTable("sound/nmc/knife/knife3.mp3");
    AddFileToDownloadsTable("sound/admin_plugin/join_admin.mp3");
    AddFileToDownloadsTable("sound/admin_plugin/actions/endofvote.mp3");
    AddFileToDownloadsTable("sound/match/tbeep1.mp3");
    AddFileToDownloadsTable("sound/match/tbeep2.mp3");
    AddFileToDownloadsTable("sound/match/tlbeep1.mp3");
    AddFileToDownloadsTable("sound/g7/thounder.mp3");

    // Always re-check (not just "if null") so that if the modes
    // plugin was reloaded mid-map and our cached handle went stale,
    // we recover without needing a plugin reload of our own.
    EnsureCurModeConVar();

    if (g_cvMaxRounds == null)
        g_cvMaxRounds = FindConVar("mp_maxrounds");
}

// FindConVar returns the same cached Handle value for repeated calls
// on an unchanged convar, so this comparison is a safe no-op when
// nothing changed, and correctly detects + re-hooks a convar that
// was destroyed/recreated by a reload of the (separate) modes plugin.
void EnsureCurModeConVar()
{
    ConVar cv = FindConVar("wh1tes_curmode");
    if (cv == g_cvCurMode)
        return;

    g_cvCurMode = cv;
    if (g_cvCurMode != null)
        g_cvCurMode.AddChangeHook(OnCurModeChanged);
}

bool IsMatchMode()
{
    return g_cvCurMode != null && g_cvCurMode.IntValue == 1;
}

// ---- knife hit sound (to the attacker) ----
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    char weapon[24];
    event.GetString("weapon", weapon, sizeof(weapon));
    if (!StrEqual(weapon, "knife"))
        return;
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker))
        return;
    EmitSoundToClient(attacker, g_sKnife[GetRandomInt(0, 2)]);
}

// ---- admin join sound ----
public void OnClientPutInServer(int client)
{
    g_bAdminAnnounced[client] = false;
    g_iAdminCheckAttempts[client] = 0;
    if (!IsFakeClient(client))
        CreateTimer(ADMIN_CHECK_INTERVAL, Timer_CheckAdmin, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_CheckAdmin(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || g_bAdminAnnounced[client])
        return Plugin_Stop;

    if (GetUserAdmin(client) != INVALID_ADMIN_ID)
    {
        g_bAdminAnnounced[client] = true;
        EmitSoundToAll("admin_plugin/join_admin.mp3");
        return Plugin_Stop;
    }

    // Admin plugins (perma-admin file / password / IP auth) may bind
    // GetUserAdmin a few seconds after PutInServer; retry a few times
    // before giving up instead of a single fragile check.
    if (++g_iAdminCheckAttempts[client] >= ADMIN_CHECK_MAX_ATTEMPTS)
        return Plugin_Stop;

    return Plugin_Continue;
}

// ---- match sounds ----
public void OnCurModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) == 1) // Match just activated
    {
        g_bBeepFlip = false; // deterministic beep order at the start of every match
        EmitSoundToAll("match/tlbeep1.mp3");
        EmitSoundToAll("g7/thounder.mp3");
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsMatchMode())
        return;
    g_bBeepFlip = !g_bBeepFlip;
    EmitSoundToAll(g_bBeepFlip ? "match/tbeep1.mp3" : "match/tbeep2.mp3");
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsMatchMode())
        return;
    if (g_cvMaxRounds == null || g_cvMaxRounds.IntValue <= 0)
        return;
    if (GetTeamScore(2) + GetTeamScore(3) >= g_cvMaxRounds.IntValue)
        EmitSoundToAll("admin_plugin/actions/endofvote.mp3");
}
