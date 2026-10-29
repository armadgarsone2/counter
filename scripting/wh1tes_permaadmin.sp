#include <sourcemod>

public Plugin myinfo =
{
    name = "Wh1Tes PermaAdmin",
    author = "Muse",
    description = "Permanent admins from a file (no setinfo needed)",
    version = "1.0.0",
    url = ""
};

#define PERMA_FILE "addons/sourcemod/configs/wh1tes_perma_admins.txt"

bool g_bGranted[MAXPLAYERS + 1];
Handle g_hTimer = null;

public void OnPluginStart()
{
    g_hTimer = CreateTimer(15.0, Timer_Check, _, TIMER_REPEAT);
    LogMessage("[PermaAdmin] Plugin loaded, checking %s", PERMA_FILE);
}

public void OnMapStart()
{
    if (g_hTimer != null)
    {
        KillTimer(g_hTimer);
        g_hTimer = null;
    }
    g_hTimer = CreateTimer(15.0, Timer_Check, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
    g_bGranted[client] = false;

    if (IsFakeClient(client))
    {
        return;
    }

    ArrayList list = LoadAdminNames();
    if (list == null)
    {
        return;
    }

    GrantIfMatch(client, list);
    delete list;
}

public void OnClientDisconnect(int client)
{
    g_bGranted[client] = false;
}

public Action Timer_Check(Handle timer)
{
    ArrayList list = LoadAdminNames();
    if (list == null)
    {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !g_bGranted[i])
        {
            GrantIfMatch(i, list);
        }
    }

    delete list;
    return Plugin_Continue;
}

ArrayList LoadAdminNames()
{
    File f = OpenFile(PERMA_FILE, "r");
    if (f == null)
    {
        LogError("[PermaAdmin] Could not open %s", PERMA_FILE);
        return null;
    }

    ArrayList list = new ArrayList(ByteCountToCells(64));
    char line[64];

    while (f.ReadLine(line, sizeof(line)))
    {
        TrimString(line);

        if (line[0] == 0 || (line[0] == '/' && line[1] == '/'))
        {
            continue;
        }

        list.PushString(line);
    }

    delete f;
    return list;
}

bool IsNameInList(const char[] name, ArrayList list)
{
    char buf[64];
    int len = list.Length;

    for (int i = 0; i < len; i++)
    {
        list.GetString(i, buf, sizeof(buf));
        if (StrEqual(name, buf, false))
        {
            return true;
        }
    }

    return false;
}

void GrantIfMatch(int client, ArrayList list)
{
    if (!IsClientInGame(client) || IsFakeClient(client) || g_bGranted[client])
    {
        return;
    }

    char name[64];
    GetClientName(client, name, sizeof(name));
    TrimString(name);

    if (!IsNameInList(name, list))
    {
        return;
    }

    AdminId admin = CreateAdmin("PermaAdmin");
    SetAdminFlag(admin, Admin_Root, true);
    SetUserAdmin(client, admin, true);
    g_bGranted[client] = true;

    LogMessage("[PermaAdmin] Granted root to %N (from file)", client);
}
