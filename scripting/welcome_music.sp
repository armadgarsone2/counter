#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Welcome Music - Clean On Spawn",
    author = "Hermes",
    description = "Plays random welcome music strictly on first spawn after team selection",
    version = "4.0",
    url = ""
};

char g_WelcomeTracks[3][] = {
    "misc/welcome.mp3",
    "misc/welcome2.mp3",
    "misc/welcome3.mp3"
};

char g_TrackNames[3][] = {
    "SYSTEM MUSIC - Latin/Rap Mix #1",
    "SYSTEM MUSIC - Beat Mix #2",
    "SYSTEM MUSIC - Beat Mix #3"
};

bool g_HasWelcomed[MAXPLAYERS + 1];

public void OnClientPutInServer(int client) {
    g_HasWelcomed[client] = false;
}

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart() {
    AddFileToDownloadsTable("sound/misc/welcome.mp3");
    AddFileToDownloadsTable("sound/misc/welcome2.mp3");
    AddFileToDownloadsTable("sound/misc/welcome3.mp3");
    PrecacheSound("misc/welcome.mp3", true);
    PrecacheSound("misc/welcome2.mp3", true);
    PrecacheSound("misc/welcome3.mp3", true);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && !g_HasWelcomed[client]) {
        int team = GetClientTeam(client);
        if (team > 1) { // Joined T or CT
            g_HasWelcomed[client] = true;
            int random = GetRandomInt(0, 2);
            ClientCommand(client, "play %s", g_WelcomeTracks[random]);
            PrintToChat(client, "\x04[Welcome] \x03Now Playing: %s", g_TrackNames[random]);
        }
    }
    return Plugin_Continue;
}