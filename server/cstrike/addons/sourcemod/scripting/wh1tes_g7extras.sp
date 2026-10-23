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
    version = "1.0.0",
    url = ""
};

char g_sKnife[][] = { "nmc/knife/knife1.mp3", "nmc/knife/knife2.mp3", "nmc/knife/knife3.mp3" };
bool g_bAdminAnnounced[MAXPLAYERS + 1];
bool g_bBeepFlip;
ConVar g_cvCurMode;

public void OnPluginStart()
{
    // late-load safe precaches (also in OnMapStart)
    PrecacheSound("nmc/knife/knife1.mp3", true);
    PrecacheSound("nmc/knife/knife2.mp3", true);
    PrecacheSound("nmc/knife/knife3.mp3", true);
    PrecacheSound("admin_plugin/join_admin.mp3", true);
    PrecacheSound("match/tbeep1.mp3", true);
    PrecacheSound("g7/thounder.mp3", true);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    g_cvCurMode = FindConVar("wh1tes_curmode");
    if (g_cvCurMode != null)
        g_cvCurMode.AddChangeHook(OnCurModeChanged);
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

    if (g_cvCurMode == null)
    {
        g_cvCurMode = FindConVar("wh1tes_curmode");
        if (g_cvCurMode != null)
            g_cvCurMode.AddChangeHook(OnCurModeChanged);
    }
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
    if (!IsFakeClient(client))
        CreateTimer(3.0, Timer_CheckAdmin, GetClientUserId(client));
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
    }
    return Plugin_Stop;
}

// ---- match sounds ----
public void OnCurModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) == 1) // Match just activated
    {
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
    ConVar cvMR = FindConVar("mp_maxrounds");
    if (cvMR == null || cvMR.IntValue <= 0)
        return;
    if (GetTeamScore(2) + GetTeamScore(3) >= cvMR.IntValue)
        EmitSoundToAll("admin_plugin/actions/endofvote.mp3");
}
