#pragma semicolon 1
#include <sourcemod>

// Wh1Tes Auth — restores in-game admin/VIP binding on this No-Steam build.
// The engine never completes client authorization (auth stays
// STEAM_ID_PENDING), so SourceMod's OnClientPostAdminCheck never fires and
// admins_simple.ini entries never bind: no !admin, no VIP "o" flag, and
// dependent plugins (rank) starve. This plugin binds manually at
// PutInServer: exact name + the client's _password -> root admin;
// matching IP -> VIP (flag "o"). Secrets live only in
// addons/sourcemod/configs/wh1tes_auth.cfg (chmod 600, server-side).

public Plugin myinfo = {
    name = "Wh1Tes Auth",
    author = "Wh1Tes",
    description = "Manual admin/VIP binding for the No-Steam build (PutInServer)",
    version = "1.2.1"
};

char g_sRootName[64];
char g_sRootPw[64];
char g_sVipIp[32];
bool g_bPwLogged[MAXPLAYERS + 1];

public void OnPluginStart()
{
    KeyValues kv = new KeyValues("Wh1TesAuth");
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/wh1tes_auth.cfg");
    if (kv.ImportFromFile(path))
    {
        kv.GetString("root_name", g_sRootName, sizeof(g_sRootName), "");
        kv.GetString("root_password", g_sRootPw, sizeof(g_sRootPw), "");
        kv.GetString("vip_ip", g_sVipIp, sizeof(g_sVipIp), "");
    }
    else
    {
        LogMessage("[Wh1Tes Auth] WARNING: could not import %s (missing or unreadable) — binding will be disabled until it exists", path);
    }
    delete kv;

    LogMessage("[Wh1Tes Auth] ready (root name set: %s, vip ip set: %s)",
        g_sRootName[0] ? "yes" : "NO", g_sVipIp[0] ? "yes" : "NO");

    // Single repeating rebind timer for the lifetime of this plugin load.
    // TIMER_FLAG_NO_MAPCHANGE means this survives every future map change
    // on its own, so it must NOT also be (re)created in OnMapStart —
    // doing that created a duplicate repeating timer on every map load
    // (fixed in v1.2.1: see OnMapStart below).
    CreateTimer(15.0, Timer_Rebind, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    // Late load: players already in game (e.g. after a plugin reload)
    // never re-fire OnClientPutInServer, so bind them from here too.
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            CreateTimer(1.5, Timer_Bind, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
}

// v1.2.1: intentionally does NOT create another rebind timer here.
// The one created in OnPluginStart already uses TIMER_FLAG_NO_MAPCHANGE
// and therefore already ticks across every map change. Re-creating it
// here as well (the old v1.2.0 behavior) produced one extra permanent
// repeating timer per map change, compounding forever for the life of
// the server process.
public void OnMapStart()
{
}

public Action Timer_Rebind(Handle timer)
{
    // Continuous invariant (v1.2.0): the bot's sm_reloadadmins dumps
    // the admin cache and unbinds in-game admins, and a player may
    // setinfo _password only after joining. Re-check the unbound.
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i)
            && GetUserAdmin(i) == INVALID_ADMIN_ID)
            BindClient(i);
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    CreateTimer(1.5, Timer_Bind, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int client)
{
    g_bPwLogged[client] = false;
}

public Action Timer_Bind(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
        BindClient(client);
    return Plugin_Stop;
}

void BindClient(int client)
{
    if (GetUserAdmin(client) != INVALID_ADMIN_ID)
        return;

    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    if (g_sRootName[0] && StrEqual(name, g_sRootName))
    {
        char pw[64];
        GetClientInfo(client, "_password", pw, sizeof(pw));
        if (g_sRootPw[0] && StrEqual(pw, g_sRootPw))
        {
            // Fresh AdminId per bind (v1.0.1): ids created in OnPluginStart
            // go stale whenever the admin cache is dumped (map change /
            // sm_reloadadmins) and SetUserAdmin then throws "AdminId is
            // invalid" — that is exactly how the VIP bind died on
            // 2026-10-23 13:48 UTC. An id created in this same frame
            // cannot be stale.
            AdminId adm = CreateAdmin("Wh1TesRoot");
            SetAdminFlag(adm, Admin_Root, true);
            SetAdminImmunityLevel(adm, 99);
            if (SetUserAdmin(client, adm, true))
                LogMessage("[Wh1Tes Auth] ROOT granted to %N", client);
            return;
        }
    }

    if (g_sVipIp[0])
    {
        char ip[32];
        GetClientIP(client, ip, sizeof(ip));
        if (StrEqual(ip, g_sVipIp))
        {
            AdminId adm = CreateAdmin("Wh1TesVIP");
            SetAdminFlag(adm, Admin_Custom1, true);
            SetAdminImmunityLevel(adm, 10);
            if (SetUserAdmin(client, adm, true))
                LogMessage("[Wh1Tes Auth] VIP granted to %N", client);
        }
    }

    // Generic admins_simple.ini binding (v1.1.0): the flatfile reader
    // creates AdminIds for every ini entry, but on this build the core
    // never binds them (authorization never completes). Bind them here:
    // find the client's AdminId by name identity, else by IP identity,
    // and enforce the entry password (when it has one) against the
    // client's _password before SetUserAdmin.
    if (GetUserAdmin(client) != INVALID_ADMIN_ID)
        return;

    AdminId ini = FindAdminByIdentity("name", name);
    if (ini == INVALID_ADMIN_ID)
    {
        char ip2[32];
        GetClientIP(client, ip2, sizeof(ip2));
        ini = FindAdminByIdentity("ip", ip2);
    }
    if (ini == INVALID_ADMIN_ID)
        return;

    char need[64];
    bool pwreq = GetAdminPassword(ini, need, sizeof(need)) && need[0];
    if (pwreq)
    {
        char pw2[64];
        GetClientInfo(client, "_password", pw2, sizeof(pw2));
        if (!StrEqual(pw2, need))
        {
            if (!g_bPwLogged[client])
            {
                g_bPwLogged[client] = true;
                LogMessage("[Wh1Tes Auth] %N matched an admin entry but the password did not match", client);
            }
            return;
        }
    }
    if (SetUserAdmin(client, ini, true))
        LogMessage("[Wh1Tes Auth] INI admin granted to %N", client);
}
