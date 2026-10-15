#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Force Skins & Models Manager",
    author = "Hermes",
    description = "Forces custom player models and weapon skins replacement",
    version = "2.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("weapon_fire", Event_WeaponFire);
}

public void OnMapStart() {
    // Precache custom models if exist
    PrecacheModel("models/player/t_arctic.mdl", true);
    PrecacheModel("models/player/ct_gign.mdl", true);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
        int team = GetClientTeam(client);
        if (team == 2) {
            SetEntityModel(client, "models/player/t_arctic.mdl");
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 0, 0, 255);
        } else if (team == 3) {
            SetEntityModel(client, "models/player/ct_gign.mdl");
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 128, 255, 255);
        }
        
        // Force active weapon color
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_GLOW);
            SetEntityRenderColor(weapon, 255, 215, 0, 255); // Gold
        }
    }
    return Plugin_Continue;
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if (weapon > 0 && IsValidEntity(weapon)) {
            SetEntityRenderMode(weapon, RENDER_GLOW);
            SetEntityRenderColor(weapon, 255, 100, 0, 255);
        }
    }
    return Plugin_Continue;
}
