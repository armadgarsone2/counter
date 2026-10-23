#include <sourcemod>

public Plugin:myinfo = {
    name = "Wh1Tes ResetScore",
    author = "Muse",
    description = "Reset your own score with !res",
    version = "1.0.0",
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_res", Cmd_Reset, "Reset your own score");
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
    if (client > 0 && IsClientInGame(client))
    {
        if (StrEqual(sArgs, "!res", false) || StrEqual(sArgs, "/res", false) ||
            StrEqual(sArgs, "!rs", false) || StrEqual(sArgs, "/rs", false) ||
            StrEqual(sArgs, "!resetscore", false) || StrEqual(sArgs, "/resetscore", false))
        {
            DoReset(client);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:Cmd_Reset(client, args)
{
    if (client > 0 && IsClientInGame(client))
        DoReset(client);
    return Plugin_Handled;
}

DoReset(client)
{
    SetEntProp(client, Prop_Data, "m_iFrags", 0);
    SetEntProp(client, Prop_Data, "m_iDeaths", 0);
    PrintToChat(client, "[Wh1Tes] Your score has been reset.");
}
