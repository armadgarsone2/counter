#include <sourcemod>

public Plugin myinfo =
{
    name = "Wh1Tes Panel2",
    author = "Muse",
    description = "Blocks old admin triggers; English panel is /panel2 via Admin Panel",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    AddCommandListener(Listener_SmAdmin, "sm_admin");
    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");
    LogMessage("[Panel2] Loaded: English panel is /panel2; /admin, !admin, /panel1, !panel1, /panel, !panel blocked");
}

public Action Listener_SmAdmin(int client, const char[] command, int argc)
{
    if (client == 0)
    {
        return Plugin_Continue;
    }
    if (client < 1 || client > MaxClients)
    {
        return Plugin_Continue;
    }
    return Plugin_Handled;
}

public Action Listener_Say(int client, const char[] command, int argc)
{
    if (client == 0)
    {
        return Plugin_Continue;
    }
    if (client < 1 || client > MaxClients)
    {
        return Plugin_Continue;
    }
    char text[128];
    GetCmdArgString(text, sizeof(text));
    TrimString(text);
    int space = FindCharInString(text, ' ');
    if (space != -1)
    {
        text[space] = '\0';
    }
    if (StrEqual(text, "/admin", false) || StrEqual(text, "!admin", false)
        || StrEqual(text, "/panel1", false) || StrEqual(text, "!panel1", false)
        || StrEqual(text, "/panel", false) || StrEqual(text, "!panel", false))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}
