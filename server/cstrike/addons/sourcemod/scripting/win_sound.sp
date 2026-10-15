#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Win/Lose Round Sounds",
    author = "Hermes",
    description = "Plays custom sounds on round end for winners/losers",
    version = "1.1",
    url = ""
};

public void OnPluginStart() {
    HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart() {
    AddFileToDownloadsTable("sound/misc/win.ogg");
    AddFileToDownloadsTable("sound/misc/lose.ogg");
    PrecacheSound("misc/win.ogg", true);
    PrecacheSound("misc/lose.ogg", true);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    int winner = event.GetInt("winner");
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            int team = GetClientTeam(i);
            if ((winner == 2 && team == 2) || (winner == 3 && team == 3)) {
                ClientCommand(i, "play misc/win.ogg");
            } else if (winner == 2 || winner == 3) {
                ClientCommand(i, "play misc/lose.ogg");
            }
        }
    }
    return Plugin_Continue;
}
