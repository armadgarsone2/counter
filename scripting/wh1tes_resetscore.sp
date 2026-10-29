#include <sourcemod>

public Plugin:myinfo = {
    name = "Wh1Tes ResetScore",
    author = "Muse",
    description = "Reset your own score with !res",
    version = "1.0.0",
    url = ""
};

new Float:g_fLastReset[MAXPLAYERS + 1];

public OnPluginStart()
{
    RegConsoleCmd("sm_res", Cmd_Reset, "Reset your own score");
}

public OnClientDisconnect(client)
{
    g_fLastReset[client] = 0.0;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        decl String:sTrimmed[64];
        strcopy(sTrimmed, sizeof(sTrimmed), sArgs);
        TrimString(sTrimmed);

        if (StrEqual(sTrimmed, "!res", false) || StrEqual(sTrimmed, "/res", false) ||
            StrEqual(sTrimmed, "!rs", false) || StrEqual(sTrimmed, "/rs", false) ||
            StrEqual(sTrimmed, "!resetscore", false) || StrEqual(sTrimmed, "/resetscore", false))
        {
            TryReset(client);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:Cmd_Reset(client, args)
{
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
        TryReset(client);
    return Plugin_Handled;
}

TryReset(client)
{
    new Float:fNow = GetEngineTime();
    if (fNow - g_fLastReset[client] < 5.0)
    {
        PrintToChat(client, "[Wh1Tes] Please wait before resetting your score again.");
        return;
    }
    g_fLastReset[client] = fNow;

    DoReset(client);
}

DoReset(client)
{
    SetEntProp(client, Prop_Data, "m_iFrags", 0);
    SetEntProp(client, Prop_Data, "m_iDeaths", 0);
    PrintToChat(client, "[Wh1Tes] Your score has been reset.");
}
