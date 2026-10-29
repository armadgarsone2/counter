#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes Who",
    author = "Wh1Tes",
    description = "Debug: sm_modelof <name> / sm_accessof <name>",
    version = "1.1.0"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_modelof", Cmd_ModelOf, ADMFLAG_GENERIC, "sm_modelof <name>");
    RegAdminCmd("sm_accessof", Cmd_AccessOf, ADMFLAG_GENERIC, "sm_accessof <name>");
}

public Action Cmd_ModelOf(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "usage: sm_modelof <name>");
        return Plugin_Handled;
    }
    char target[MAX_NAME_LENGTH];
    GetCmdArg(1, target, sizeof(target));
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        char nm[MAX_NAME_LENGTH];
        GetClientName(i, nm, sizeof(nm));
        if (StrContains(nm, target, false) != -1)
        {
            char model[PLATFORM_MAX_PATH];
            GetClientModel(i, model, sizeof(model));
            ReplyToCommand(client, "MODEL %s (team %d, slot %d): %s", nm, GetClientTeam(i), i, model);
        }
    }
    return Plugin_Handled;
}

public Action Cmd_AccessOf(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "usage: sm_accessof <name>");
        return Plugin_Handled;
    }
    char target[MAX_NAME_LENGTH];
    GetCmdArg(1, target, sizeof(target));
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        char nm[MAX_NAME_LENGTH];
        GetClientName(i, nm, sizeof(nm));
        if (StrContains(nm, target, false) != -1)
        {
            char ip[32], auth[64];
            GetClientIP(i, ip, sizeof(ip));
            GetClientAuthId(i, AuthId_Engine, auth, sizeof(auth));
            AdminId adm = GetUserAdmin(i);
            bool root = CheckCommandAccess(i, "", ADMFLAG_ROOT, true);
            bool vip  = CheckCommandAccess(i, "", ADMFLAG_CUSTOM1, true);
            ReplyToCommand(client, "ACCESS %s ip=%s auth=%s admin=%s root=%s vip_o=%s",
                nm, ip, auth,
                adm != INVALID_ADMIN_ID ? "YES" : "NO",
                root ? "YES" : "NO",
                vip ? "YES" : "NO");
        }
    }
    return Plugin_Handled;
}
