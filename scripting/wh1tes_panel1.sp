#include <sourcemod>
#include <adminmenu>

public Plugin myinfo =
{
    name = "Wh1Tes Panel1",
    author = "Muse",
    description = "/panel1 -> English stock menu, /PANEL1 -> Persian Admin Panel, /admin -> hint only",
    version = "3.0.0",
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_panel1", Cmd_English, ADMFLAG_GENERIC, "Open English admin menu");
    RegAdminCmd("sm_PANEL1", Cmd_Persian, ADMFLAG_GENERIC, "Open Persian admin panel");
    RegAdminCmd("sm_admin", Cmd_AdminHint, ADMFLAG_GENERIC, "Admin menu moved to /panel1 and /PANEL1");
    LogMessage("[Panel1] Loaded v3.0.0: sm_panel1 -> English, sm_PANEL1 -> Persian, sm_admin -> hint");
}

public Action Cmd_English(int client, int args)
{
    if (client == 0)
    {
        return Plugin_Handled;
    }
    TopMenu top = GetAdminTopMenu();
    if (top != INVALID_HANDLE)
    {
        DisplayTopMenu(top, client, TopMenuPosition_Start);
        LogMessage("[Panel1] /panel1 from %N -> English TopMenu", client);
    }
    else
    {
        PrintToChat(client, "[Server] Admin menu not available");
        LogMessage("[Panel1] /panel1 from %N -> TopMenu INVALID", client);
    }
    return Plugin_Handled;
}

public Action Cmd_Persian(int client, int args)
{
    if (client == 0)
    {
        return Plugin_Handled;
    }
    if (!CommandExists("sm_fapanel"))
    {
        PrintToChat(client, "[Server] Persian admin panel is not loaded right now");
        LogMessage("[Panel1] /PANEL1 from %N -> sm_fapanel NOT FOUND (is admin_panel plugin loaded?)", client);
        return Plugin_Handled;
    }
    LogMessage("[Panel1] /PANEL1 from %N -> Persian sm_fapanel", client);
    FakeClientCommand(client, "sm_fapanel");
    return Plugin_Handled;
}

public Action Cmd_AdminHint(int client, int args)
{
    if (client == 0)
    {
        return Plugin_Handled;
    }
    PrintToChat(client, "[Server] English: /panel1 | Persian: /PANEL1");
    LogMessage("[Panel1] /admin from %N -> hint (override active)", client);
    return Plugin_Handled;
}
