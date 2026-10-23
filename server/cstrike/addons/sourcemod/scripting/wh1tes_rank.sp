
#include <sourcemod>
#include <sdktools>

#define PTS_KILL     3
#define PTS_HEADSHOT 1
#define PTS_KNIFE    2
#define PTS_DEATH   -1

new Handle:g_hDB = INVALID_HANDLE;
new g_iPoints[MAXPLAYERS + 1];
new g_iKills[MAXPLAYERS + 1];
new g_iDeaths[MAXPLAYERS + 1];
new g_iHeadshots[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new String:g_sKey[MAXPLAYERS + 1][64];

public Plugin:myinfo =
{
    name = "Wh1Tes Rank",
    author = "Muse",
    description = "SQLite rank system: !rank / !top / !guns",
    version = "1.1.0",
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_rank", Cmd_Rank, "Show your rank");
    RegConsoleCmd("sm_top", Cmd_Top, "Show top 10 players");
    RegConsoleCmd("sm_guns", Cmd_Guns, "Weapon leaderboards");
    RegConsoleCmd("sm_gun", Cmd_Gun, "Top 5 for one weapon: sm_gun <weapon>");
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    ConnectDB();
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            LoadPlayer(i);
}

public OnMapStart()
{
    if (g_hDB == INVALID_HANDLE)
        ConnectDB();
}

ConnectDB()
{
    if (g_hDB != INVALID_HANDLE)
        return;
    new String:err[255];
    g_hDB = SQL_Connect("storage-local", true, err, sizeof(err));
    if (g_hDB == INVALID_HANDLE)
    {
        LogError("[Wh1Tes Rank] DB connect failed: %s", err);
        return;
    }
    SQL_SetCharset(g_hDB, "utf8");
    SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS ranks (id TEXT PRIMARY KEY, name TEXT, points INTEGER DEFAULT 0, kills INTEGER DEFAULT 0, deaths INTEGER DEFAULT 0, headshots INTEGER DEFAULT 0)");
    SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS weapon_kills (id TEXT, name TEXT, weapon TEXT, kills INTEGER DEFAULT 0, PRIMARY KEY (id, weapon))");
    new n = 0;
    new Handle:q = SQL_Query(g_hDB, "SELECT COUNT(*) FROM ranks");
    if (q != INVALID_HANDLE)
    {
        if (SQL_FetchRow(q))
            n = SQL_FetchInt(q, 0);
        CloseHandle(q);
    }
    LogMessage("[Wh1Tes Rank] DB ready, %d players tracked.", n);
}

MakeKey(client, String:key[], maxlen)
{
    new String:auth[64];
    GetClientAuthString(client, auth, sizeof(auth));
    if (StrEqual(auth, "STEAM_ID_PENDING") || StrEqual(auth, "STEAM_ID_LAN")
        || StrEqual(auth, "STEAM_0:0:0") || StrEqual(auth, "STEAM_0:1:0")
        || StrContains(auth, "VALVE_") == 0 || auth[0] == 0)
        GetClientName(client, key, maxlen);
    else
        strcopy(key, maxlen, auth);
    ReplaceString(key, maxlen, "'", "");
}

public OnClientPostAdminCheck(client)
{
    TryLoad(client);
}

// This No-Steam build never completes client authorization, so
// OnClientPostAdminCheck never fires (root cause of the empty ranks table,
// broken in-game admin binding and missing VIP flags). Load on PutInServer
// instead; TryLoad is idempotent via g_bLoaded.
public OnClientPutInServer(client)
{
    CreateTimer(1.0, Timer_TryLoad, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_TryLoad(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
        TryLoad(client);
    return Plugin_Stop;
}

TryLoad(client)
{
    if (IsFakeClient(client) || g_bLoaded[client])
        return;
    LoadPlayer(client);
}

LoadPlayer(client)
{
    if (g_hDB == INVALID_HANDLE)
        return;
    MakeKey(client, g_sKey[client], 64);

    new String:esc[128], String:q[512];
    SQL_EscapeString(g_hDB, g_sKey[client], esc, sizeof(esc));
    Format(q, sizeof(q), "SELECT points,kills,deaths,headshots FROM ranks WHERE id='%s'", esc);
    new Handle:res = SQL_Query(g_hDB, q);
    new bool:found = false;
    if (res != INVALID_HANDLE)
    {
        if (SQL_FetchRow(res))
        {
            g_iPoints[client]    = SQL_FetchInt(res, 0);
            g_iKills[client]     = SQL_FetchInt(res, 1);
            g_iDeaths[client]    = SQL_FetchInt(res, 2);
            g_iHeadshots[client] = SQL_FetchInt(res, 3);
            found = true;
        }
        CloseHandle(res);
    }

    new String:name[64], String:escname[128];
    GetClientName(client, name, sizeof(name));
    SQL_EscapeString(g_hDB, name, escname, sizeof(escname));
    if (!found)
    {
        g_iPoints[client] = g_iKills[client] = g_iDeaths[client] = g_iHeadshots[client] = 0;
        Format(q, sizeof(q), "INSERT OR IGNORE INTO ranks (id,name,points,kills,deaths,headshots) VALUES ('%s','%s',0,0,0,0)", esc, escname);
        SQL_FastQuery(g_hDB, q);
    }
    else
    {
        Format(q, sizeof(q), "UPDATE ranks SET name='%s' WHERE id='%s'", escname, esc);
        SQL_FastQuery(g_hDB, q);
    }
    g_bLoaded[client] = true;
}

public OnClientDisconnect(client)
{
    if (g_hDB != INVALID_HANDLE && g_bLoaded[client] && g_sKey[client][0])
        SavePlayer(client);
    g_bLoaded[client] = false;
}

SavePlayer(client)
{
    if (g_hDB == INVALID_HANDLE)
        return;
    new String:esc[128], String:q[512];
    SQL_EscapeString(g_hDB, g_sKey[client], esc, sizeof(esc));
    Format(q, sizeof(q),
        "UPDATE ranks SET points=%d,kills=%d,deaths=%d,headshots=%d WHERE id='%s'",
        g_iPoints[client], g_iKills[client], g_iDeaths[client], g_iHeadshots[client], esc);
    SQL_FastQuery(g_hDB, q);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && g_bLoaded[victim])
    {
        g_iDeaths[victim]++;
        g_iPoints[victim] += PTS_DEATH;
        if (g_iPoints[victim] < 0)
            g_iPoints[victim] = 0;
        SavePlayer(victim);
    }

    if (attacker < 1 || attacker > MaxClients || attacker == victim
        || !IsClientInGame(attacker) || IsFakeClient(attacker) || !g_bLoaded[attacker])
        return;

    g_iKills[attacker]++;
    new pts = PTS_KILL;
    new String:weapon[32];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    if (GetEventBool(event, "headshot"))
    {
        g_iHeadshots[attacker]++;
        pts += PTS_HEADSHOT;
    }
    if (StrEqual(weapon, "knife"))
        pts += PTS_KNIFE;
    g_iPoints[attacker] += pts;
    SavePlayer(attacker);
    RecordWeaponKill(attacker, weapon);
}

RecordWeaponKill(client, const String:weapon[])
{
    if (g_hDB == INVALID_HANDLE || weapon[0] == 0)
        return;
    new String:name[64], String:escname[128], String:escw[64], String:escid[128], String:q[512];
    GetClientName(client, name, sizeof(name));
    SQL_EscapeString(g_hDB, name, escname, sizeof(escname));
    SQL_EscapeString(g_hDB, weapon, escw, sizeof(escw));
    SQL_EscapeString(g_hDB, g_sKey[client], escid, sizeof(escid));
    Format(q, sizeof(q), "INSERT OR IGNORE INTO weapon_kills (id,name,weapon,kills) VALUES ('%s','%s','%s',0)", escid, escname, escw);
    SQL_FastQuery(g_hDB, q);
    Format(q, sizeof(q), "UPDATE weapon_kills SET kills=kills+1, name='%s' WHERE id='%s' AND weapon='%s'", escname, escid, escw);
    SQL_FastQuery(g_hDB, q);
}

PrettyWeapon(const String:weapon[], String:out[], maxlen)
{
    if (StrEqual(weapon, "m4a1")) strcopy(out, maxlen, "M4A1");
    else if (StrEqual(weapon, "ak47")) strcopy(out, maxlen, "AK-47");
    else if (StrEqual(weapon, "awp")) strcopy(out, maxlen, "AWP");
    else if (StrEqual(weapon, "deagle")) strcopy(out, maxlen, "Desert Eagle");
    else if (StrEqual(weapon, "usp")) strcopy(out, maxlen, "USP");
    else if (StrEqual(weapon, "glock")) strcopy(out, maxlen, "Glock");
    else if (StrEqual(weapon, "p228")) strcopy(out, maxlen, "P228");
    else if (StrEqual(weapon, "fiveseven")) strcopy(out, maxlen, "Five-Seven");
    else if (StrEqual(weapon, "elite")) strcopy(out, maxlen, "Dual Elites");
    else if (StrEqual(weapon, "m3")) strcopy(out, maxlen, "M3 Shotgun");
    else if (StrEqual(weapon, "xm1014")) strcopy(out, maxlen, "XM1014");
    else if (StrEqual(weapon, "mac10")) strcopy(out, maxlen, "MAC-10");
    else if (StrEqual(weapon, "tmp")) strcopy(out, maxlen, "TMP");
    else if (StrEqual(weapon, "mp5navy")) strcopy(out, maxlen, "MP5");
    else if (StrEqual(weapon, "ump45")) strcopy(out, maxlen, "UMP45");
    else if (StrEqual(weapon, "p90")) strcopy(out, maxlen, "P90");
    else if (StrEqual(weapon, "galil")) strcopy(out, maxlen, "Galil");
    else if (StrEqual(weapon, "famas")) strcopy(out, maxlen, "FAMAS");
    else if (StrEqual(weapon, "sg552")) strcopy(out, maxlen, "SG-552");
    else if (StrEqual(weapon, "aug")) strcopy(out, maxlen, "AUG");
    else if (StrEqual(weapon, "sg550")) strcopy(out, maxlen, "SG-550");
    else if (StrEqual(weapon, "g3sg1")) strcopy(out, maxlen, "G3SG1");
    else if (StrEqual(weapon, "scout")) strcopy(out, maxlen, "Scout");
    else if (StrEqual(weapon, "m249")) strcopy(out, maxlen, "M249");
    else if (StrEqual(weapon, "knife")) strcopy(out, maxlen, "Knife");
    else if (StrEqual(weapon, "hegrenade")) strcopy(out, maxlen, "HE Grenade");
    else strcopy(out, maxlen, weapon);
}

public Action:Cmd_Gun(client, args)
{
    if (client == 0)
        return Plugin_Handled;
    if (args < 1)
    {
        return Cmd_Guns(client, 0);
    }
    new String:w[32];
    GetCmdArg(1, w, sizeof(w));
    StrToLower(w);
    if (StrEqual(w, "ak")) strcopy(w, sizeof(w), "ak47");
    else if (StrEqual(w, "m4")) strcopy(w, sizeof(w), "m4a1");
    else if (StrEqual(w, "mp5")) strcopy(w, sizeof(w), "mp5navy");
    ShowGunTop(client, w);
    return Plugin_Handled;
}

StrToLower(String:s[])
{
    new len = strlen(s);
    for (new i = 0; i < len; i++)
        if (s[i] >= 'A' && s[i] <= 'Z')
            s[i] += 32;
}

public Action:Cmd_Guns(client, args)
{
    if (client == 0 || g_hDB == INVALID_HANDLE)
        return Plugin_Handled;
    new Handle:menu = CreateMenu(GunsMenuHandler);
    SetMenuTitle(menu, "Weapon Leaderboards");
    new Handle:res = SQL_Query(g_hDB, "SELECT weapon, SUM(kills) AS total FROM weapon_kills GROUP BY weapon ORDER BY total DESC LIMIT 32");
    new count = 0;
    if (res != INVALID_HANDLE)
    {
        new String:w[32], String:pretty[48], String:line[96];
        while (SQL_FetchRow(res))
        {
            SQL_FetchString(res, 0, w, sizeof(w));
            PrettyWeapon(w, pretty, sizeof(pretty));
            Format(line, sizeof(line), "%s - %d kills", pretty, SQL_FetchInt(res, 1));
            AddMenuItem(menu, w, line);
            count++;
        }
        CloseHandle(res);
    }
    if (count == 0)
        AddMenuItem(menu, "", "No kills recorded yet", ITEMDRAW_DISABLED);
    DisplayMenu(menu, client, 30);
    return Plugin_Handled;
}

public GunsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (info[0])
            ShowGunTop(param1, info);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
    return 0;
}

ShowGunTop(client, const String:weapon[])
{
    if (g_hDB == INVALID_HANDLE)
        return;
    new String:pretty[48];
    PrettyWeapon(weapon, pretty, sizeof(pretty));
    new Handle:menu = CreateMenu(GunTopMenuHandler);
    new String:title[96];
    Format(title, sizeof(title), "%s - Top 5", pretty);
    SetMenuTitle(menu, title);
    new String:escw[64], String:q[512];
    SQL_EscapeString(g_hDB, weapon, escw, sizeof(escw));
    Format(q, sizeof(q), "SELECT name, kills FROM weapon_kills WHERE weapon='%s' ORDER BY kills DESC, name ASC LIMIT 5", escw);
    new Handle:res = SQL_Query(g_hDB, q);
    new pos = 1;
    if (res != INVALID_HANDLE)
    {
        new String:pname[64], String:line[96];
        while (SQL_FetchRow(res))
        {
            SQL_FetchString(res, 0, pname, sizeof(pname));
            Format(line, sizeof(line), "#%d %s - %d", pos, pname, SQL_FetchInt(res, 1));
            AddMenuItem(menu, "", line, ITEMDRAW_DISABLED);
            pos++;
        }
        CloseHandle(res);
    }
    if (pos == 1)
        AddMenuItem(menu, "", "No kills with this weapon yet", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "__back", "Back to weapons");
    DisplayMenu(menu, client, 30);
}

public GunTopMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (StrEqual(info, "__back"))
            Cmd_Guns(param1, 0);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
    return 0;
}

public Action:Cmd_Rank(client, args)
{
    if (client == 0 || !g_bLoaded[client])
    {
        ReplyToCommand(client, "Rank data not ready yet, try again in a few seconds.");
        return Plugin_Handled;
    }
    new rank = 1;
    new String:q[256];
    Format(q, sizeof(q), "SELECT COUNT(*)+1 FROM ranks WHERE points>%d", g_iPoints[client]);
    new Handle:res = SQL_Query(g_hDB, q);
    if (res != INVALID_HANDLE)
    {
        if (SQL_FetchRow(res))
            rank = SQL_FetchInt(res, 0);
        CloseHandle(res);
    }
    new Float:kd = g_iDeaths[client] > 0 ? float(g_iKills[client]) / float(g_iDeaths[client]) : float(g_iKills[client]);
    PrintToChat(client, "\x04 ﺎﻤﺷ ﯼﻪﺒﺗﺭ: #%d \x01| ﺯﺎﯿﺘﻣﺍ: \x03%d \x01| ﻞﯿﮐ: \x03%d \x01| ﺙﺩ: \x03%d \x01| K/D: \x03%.2f",
        rank, g_iPoints[client], g_iKills[client], g_iDeaths[client], kd);
    return Plugin_Handled;
}

public Action:Cmd_Top(client, args)
{
    if (client == 0 || g_hDB == INVALID_HANDLE)
        return Plugin_Handled;
    new Handle:menu = CreateMenu(TopMenuHandler);
    SetMenuTitle(menu, " Top 10 Players");
    new Handle:res = SQL_Query(g_hDB, "SELECT name,points,kills,deaths FROM ranks ORDER BY points DESC LIMIT 10");
    new pos = 1;
    if (res != INVALID_HANDLE)
    {
        new String:pname[64], String:line[96];
        while (SQL_FetchRow(res))
        {
            SQL_FetchString(res, 0, pname, sizeof(pname));
            Format(line, sizeof(line), "#%d %s — %d pts (%d/%d)",
                pos, pname, SQL_FetchInt(res, 1), SQL_FetchInt(res, 2), SQL_FetchInt(res, 3));
            AddMenuItem(menu, "", line, ITEMDRAW_DISABLED);
            pos++;
        }
        CloseHandle(res);
    }
    if (pos == 1)
        AddMenuItem(menu, "", "No data yet", ITEMDRAW_DISABLED);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public TopMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
        CloseHandle(menu);
    return 0;
}
