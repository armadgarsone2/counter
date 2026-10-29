/*
 * VIP Chat Tag for CS:S v34
 * Players with the "o" flag (VIPs) get a colored [VIP] tag in chat.
 *
 * Install: compile -> vip_tag.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "VIP Chat Tag",
    author      = "Server Owner",
    description = "Colored [VIP] tag in chat for VIP players",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    AddCommandListener(OnClientSay, "say");
    AddCommandListener(OnClientSay, "say_team");
}

bool IsVip(int client)
{
    return CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, true); // flag "o"
}

public Action OnClientSay(int client, const char[] command, int argc)
{
    if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;
    if (!IsVip(client))
        return Plugin_Continue;

    char text[256];
    GetCmdArgString(text, sizeof(text));
    // strip surrounding quotes added by the engine
    int len = strlen(text);
    if (len >= 2 && text[0] == '"' && text[len - 1] == '"')
    {
        text[len - 1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }
    TrimString(text);
    if (!text[0])
        return Plugin_Stop;

    bool teamOnly = StrEqual(command, "say_team");
    int team = GetClientTeam(client);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        if (teamOnly && GetClientTeam(i) != team)
            continue;
        PrintToChat(i, "\x04[VIP] \x03%N\x01: %s", client, text);
    }
    return Plugin_Stop;
}
