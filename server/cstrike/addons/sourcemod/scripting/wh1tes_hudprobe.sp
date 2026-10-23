#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes HUD Probe",
    author = "Wh1Tes",
    description = "One-off probe: does this build render ShowHudText?",
    version = "1.0.0"
};

public void OnPluginStart()
{
    RegServerCmd("sm_hudprobe", Cmd_Probe, "Show a HUD text near the top for all real players");
}

public Action Cmd_Probe(int args)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        SetHudTextParams(-1.0, 0.18, 8.0, 255, 200, 60, 255, 0, 0.0, 0.0, 0.5);
        ShowHudText(i, 2, "SCOREBOARD TEST");
    }
    PrintToServer("[hudprobe] sent to real players");
    return Plugin_Handled;
}
