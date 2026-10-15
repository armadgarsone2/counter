#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Custom Weapon Skins & Effects",
    author = "Hermes",
    description = "Gives players custom glowing weapons and trails on spawn",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        // Give weapon glow / color effects via datamap
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
            SetEntityRenderColor(weapon, 255, 215, 0, 255); // Gold / Shine effect on active weapon
        }
    }
    return Plugin_Continue;
}
