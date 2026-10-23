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
    version = "1.0.1"
};

char g_sRootName[64];
char g_sRootPw[64];
char g_sVipIp[32];

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
    delete kv;

    LogMessage("[Wh1Tes Auth] ready (root name set: %s, vip ip set: %s)",
        g_sRootName[0] ? "yes" : "NO", g_sVipIp[0] ? "yes" : "NO");

    // Late load: players already in game (e.g. after a plugin reload)
    // never re-fire OnClientPutInServer, so bind them from here too.
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            CreateTimer(1.5, Timer_Bind, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
    CreateTimer(1.5, Timer_Bind, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
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
}
