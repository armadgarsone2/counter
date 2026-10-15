/*
 * Connect Messages for CS:S v34
 * Announces when players join and leave the server.
 *
 * Install: compile -> connect_msg.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvJoin;
ConVar g_cvLeave;

public Plugin myinfo =
{
    name        = "Connect Messages",
    author      = "Server Owner",
    description = "Join/leave announcements in chat",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvJoin  = CreateConVar("sm_cm_join", "1", "Announce player joins", _, true, 0.0, true, 1.0);
    g_cvLeave = CreateConVar("sm_cm_leave", "1", "Announce player leaves", _, true, 0.0, true, 1.0);
    AutoExecConfig(true, "connect_msg");
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client) || !g_cvJoin.BoolValue)
        return;
    CreateTimer(3.0, Timer_AnnounceJoin, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AnnounceJoin(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
        PrintToChatAll("\x03%N \x04وارد سرور شد 👋", client);
    return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client) || !g_cvLeave.BoolValue)
        return;
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    PrintToChatAll("\x03%s \x01از سرور خارج شد", name);
}
