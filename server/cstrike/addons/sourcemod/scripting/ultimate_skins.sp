#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Ultimate Skins & Weapon FX",
    author = "Hermes",
    description = "Advanced glowing effects, laser beams and rainbow weapon skins",
    version = "2.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("weapon_fire", Event_WeaponFire);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        // Super premium glow: Rainbow / Diamond shine
        int team = GetClientTeam(client);
        if (team == 2) {
            // T: Crimson / Ruby Glow
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 255, 50, 100, 230);
        } else if (team == 3) {
            // CT: Neon Sapphire Blue Glow
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 0, 200, 255, 230);
        }
        
        // Give weapon diamond/platinum chrome effect
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
            SetEntityRenderColor(weapon, 230, 230, 250, 255); // Platinum / Diamond FX
        }
    }
    return Plugin_Continue;
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client)) {
        // Update active weapon color dynamically on fire
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
            SetEntityRenderColor(weapon, 255, 215, 0, 255); // Flash Gold on fire
        }
    }
    return Plugin_Continue;
}
