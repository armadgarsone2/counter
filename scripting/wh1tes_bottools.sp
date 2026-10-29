#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>

/*
 * Wh1Tes Bot Tools v1.0.0
 * Server-only commands for the Telegram management bot (driven via RCON):
 *   sm_bot_swap <userid>  -> switch the player to the other team
 *   sm_bot_scores         -> print "BOTSCORES CT=<n> T=<n>"
 */

public Plugin myinfo = {
    name = "Wh1Tes Bot Tools",
    author = "Wh1Tes",
    description = "Server commands for the Telegram bot",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    RegServerCmd("sm_bot_swap", Cmd_BotSwap, "Swap a player to the other team: sm_bot_swap <userid>");
    RegServerCmd("sm_bot_scores", Cmd_BotScores, "Print team scores for the bot");
}

public Action Cmd_BotSwap(int args)
{
    if (args < 1)
    {
        ReplyToCommand(0, "BOTSWAP_ERROR usage: sm_bot_swap <userid>");
        return Plugin_Handled;
    }
    char arg[16];
    GetCmdArg(1, arg, sizeof(arg));
    int client = GetClientOfUserId(StringToInt(arg));
    if (client <= 0 || !IsClientInGame(client))
    {
        ReplyToCommand(0, "BOTSWAP_ERROR no such player");
        return Plugin_Handled;
    }
    int team = GetClientTeam(client);
    if (team != CS_TEAM_T && team != CS_TEAM_CT)
    {
        ReplyToCommand(0, "BOTSWAP_ERROR player is not on T/CT");
        return Plugin_Handled;
    }
    int dest = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
    CS_SwitchTeam(client, dest);
    ReplyToCommand(0, "BOTSWAP_OK team=%d", dest);
    return Plugin_Handled;
}

public Action Cmd_BotScores(int args)
{
    ReplyToCommand(0, "BOTSCORES CT=%d T=%d",
        CS_GetTeamScore(CS_TEAM_CT), CS_GetTeamScore(CS_TEAM_T));
    return Plugin_Handled;
}
