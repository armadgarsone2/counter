/*
 * Simple Rank for CS:S v34 (SQLite — no MySQL needed)
 *
 * Points:  kill +3 | headshot +1 | knife +2 | death -1 (never below 0)
 * Identity: SteamID when valid, otherwise player name (non-Steam friendly)
 *
 * Commands:  !rank  - your points, rank and K/D
 *            !top   - top 10 players
 *
 * Install: compile -> simple_rank.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PTS_KILL     3
#define PTS_HEADSHOT 1
#define PTS_KNIFE    2
#define PTS_DEATH   -1

Database g_db = null;
int    g_iPoints[MAXPLAYERS + 1];
int    g_iKills[MAXPLAYERS + 1];
int    g_iDeaths[MAXPLAYERS + 1];
int    g_iHeadshots[MAXPLAYERS + 1];
bool   g_bLoaded[MAXPLAYERS + 1];
char   g_sKey[MAXPLAYERS + 1][64];

public Plugin myinfo =
{
    name        = "Simple Rank",
    author      = "Server Owner",
    description = "SQLite rank system: !rank / !top",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_rank", Cmd_Rank, "Show your rank");
    RegConsoleCmd("sm_top", Cmd_Top, "Show top 10 players");
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    SQL_TConnect(OnDBConnect, "storage-local");
}

public void OnDBConnect(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {
        LogError("[Rank] DB connect failed: %s", error);
        return;
    }
    g_db = view_as<Database>(hndl);
    g_db.Query(OnTableReady, "CREATE TABLE IF NOT EXISTS ranks (id TEXT PRIMARY KEY, name TEXT, points INTEGER DEFAULT 0, kills INTEGER DEFAULT 0, deaths INTEGER DEFAULT 0, headshots INTEGER DEFAULT 0)");

    // load already-connected players (late load)
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
            LoadPlayer(i);
}

public void OnTableReady(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
        LogError("[Rank] table create failed: %s", error);
}

void MakeKey(int client, char[] key, int maxlen)
{
    char auth[64];
    GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
    // non-Steam junk IDs -> fall back to name
    if (StrEqual(auth, "STEAM_ID_PENDING") || StrEqual(auth, "STEAM_ID_LAN")
        || StrEqual(auth, "STEAM_0:0:0") || StrEqual(auth, "STEAM_0:1:0")
        || StrContains(auth, "VALVE_") == 0 || auth[0] == '\0')
        GetClientName(client, key, maxlen);
    else
        strcopy(key, maxlen, auth);
    // sanitize single quotes
    ReplaceString(key, maxlen, "'", "");
}

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))
        return;
    g_bLoaded[client] = false;
    LoadPlayer(client);
}

void LoadPlayer(int client)
{
    if (g_db == null)
        return;
    MakeKey(client, g_sKey[client], sizeof(g_sKey[]));

    char name[64], q[256];
    GetClientName(client, name, sizeof(name));
    ReplaceString(name, sizeof(name), "'", "");
    Format(q, sizeof(q), "SELECT points,kills,deaths,headshots FROM ranks WHERE id='%s'", g_sKey[client]);
    g_db.Query(OnPlayerLoaded, q, GetClientUserId(client));

    // keep name fresh (fire and forget)
    char q2[256];
    Format(q2, sizeof(q2), "INSERT OR IGNORE INTO ranks (id,name) VALUES ('%s','%s')", g_sKey[client], name);
    g_db.Query(OnIgnore, q2);
    Format(q2, sizeof(q2), "UPDATE ranks SET name='%s' WHERE id='%s'", name, g_sKey[client]);
    g_db.Query(OnIgnore, q2);
}

public void OnIgnore(Database db, DBResultSet results, const char[] error, any data) { }

public void OnPlayerLoaded(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0)
        return;
    if (results != null && results.FetchRow())
    {
        g_iPoints[client]    = results.FetchInt(0);
        g_iKills[client]     = results.FetchInt(1);
        g_iDeaths[client]    = results.FetchInt(2);
        g_iHeadshots[client] = results.FetchInt(3);
    }
    else
    {
        g_iPoints[client] = g_iKills[client] = g_iDeaths[client] = g_iHeadshots[client] = 0;
    }
    g_bLoaded[client] = true;
}

public void OnClientDisconnect(int client)
{
    if (g_db != null && g_bLoaded[client] && g_sKey[client][0])
        SavePlayer(client);
    g_bLoaded[client] = false;
}

void SavePlayer(int client)
{
    char q[256];
    Format(q, sizeof(q),
        "UPDATE ranks SET points=%d,kills=%d,deaths=%d,headshots=%d WHERE id='%s'",
        g_iPoints[client], g_iKills[client], g_iDeaths[client], g_iHeadshots[client], g_sKey[client]);
    g_db.Query(OnIgnore, q);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && g_bLoaded[victim])
    {
        g_iDeaths[victim]++;
        g_iPoints[victim] += PTS_DEATH;
        if (g_iPoints[victim] < 0)
            g_iPoints[victim] = 0;
    }

    if (attacker < 1 || attacker > MaxClients || attacker == victim
        || !IsClientInGame(attacker) || IsFakeClient(attacker) || !g_bLoaded[attacker])
        return;

    g_iKills[attacker]++;
    int pts = PTS_KILL;
    char weapon[32];
    event.GetString("weapon", weapon, sizeof(weapon));
    if (event.GetBool("headshot"))
    {
        g_iHeadshots[attacker]++;
        pts += PTS_HEADSHOT;
    }
    if (StrEqual(weapon, "knife"))
        pts += PTS_KNIFE;
    g_iPoints[attacker] += pts;
}

public Action Cmd_Rank(int client, int args)
{
    if (client == 0 || !g_bLoaded[client])
    {
        ReplyToCommand(client, "Rank data not ready yet, try again in a few seconds.");
        return Plugin_Handled;
    }
    char q[256];
    Format(q, sizeof(q), "SELECT COUNT(*)+1 FROM ranks WHERE points>%d", g_iPoints[client]);
    g_db.Query(OnRankResult, q, GetClientUserId(client));
    return Plugin_Handled;
}

public void OnRankResult(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client))
        return;
    int rank = 1;
    if (results != null && results.FetchRow())
        rank = results.FetchInt(0);
    float kd = g_iDeaths[client] > 0 ? float(g_iKills[client]) / float(g_iDeaths[client]) : float(g_iKills[client]);
    PrintToChat(client, "\x04 ﺎﻤﺷ ﯼﻪﺒﺗﺭ: #%d \x01| ﺯﺎﯿﺘﻣﺍ: \x03%d \x01| ﻞﯿﮐ: \x03%d \x01| ﺙﺩ: \x03%d \x01| K/D: \x03%.2f",
        rank, g_iPoints[client], g_iKills[client], g_iDeaths[client], kd);
}

public Action Cmd_Top(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    g_db.Query(OnTopResult, "SELECT name,points,kills,deaths FROM ranks ORDER BY points DESC LIMIT 10", GetClientUserId(client));
    return Plugin_Handled;
}

public void OnTopResult(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client))
        return;
    Menu menu = new Menu(TopMenuHandler);
    menu.SetTitle(" Top 10 Players");
    if (results == null)
    {
        menu.AddItem("", "No data yet", ITEMDRAW_DISABLED);
    }
    else
    {
        char name[64], line[96];
        int pos = 1;
        while (results.FetchRow())
        {
            results.FetchString(0, name, sizeof(name));
            Format(line, sizeof(line), "#%d %s — %d pts (%d/%d)",
                pos, name, results.FetchInt(1), results.FetchInt(2), results.FetchInt(3));
            menu.AddItem("", line, ITEMDRAW_DISABLED);
            pos++;
        }
        if (pos == 1)
            menu.AddItem("", "No data yet", ITEMDRAW_DISABLED);
    }
    menu.Display(client, 20);
}

public int TopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
    return 0;
}
