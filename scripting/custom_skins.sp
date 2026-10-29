#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Custom Player Skins & Trails",
    author = "Hermes",
    description = "Applies custom glowing trails and visual effects on spawn",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        // Apply colorful player glow (Team-based: CT = Blue, T = Red/Orange)
        int team = GetClientTeam(client);
        if (team == 2) {
            // Terrorist: Orange/Red glow
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 255, 100, 50, 255);
        } else if (team == 3) {
            // Counter-Terrorist: Cyan/Blue glow
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 50, 150, 255, 255);
        }
    }
    return Plugin_Continue;
}
