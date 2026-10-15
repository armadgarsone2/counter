#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Force Visuals & Sounds",
    author = "Hermes",
    description = "Forces screen overlays, ambient sounds, and color enhancements",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    // Force screen fade / visual mood
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            ClientCommand(i, "r_drawothermodels 1");
            PrintCenterText(i, "=== SERVER ENHANCED & OPTIMIZED ===");
        }
    }
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
        // Vibrant neon glow on players
        int team = GetClientTeam(client);
        if (team == 2) {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 30, 30, 255);
        } else if (team == 3) {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 150, 255, 255);
        }

        // Weapon shiny gold/chrome
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_GLOW);
            SetEntityRenderColor(weapon, 255, 215, 0, 255);
        }
    }
    return Plugin_Continue;
}
