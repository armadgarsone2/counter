#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Master Visuals - All Effects",
    author = "Hermes",
    description = "Single plugin: player glow, weapon gold, kill effects, hit markers",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_activate", Event_PlayerConnectFull);
}

public Action Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
        PrintToChat(client, "\x04[MasterVisuals] \x0FLoaded: Player Glow + Weapon Gold + Kill FX");
    }
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
        ApplyPlayerEffects(client);
        ApplyWeaponEffects(client);
    }
    return Plugin_Continue;
}

public void ApplyPlayerEffects(int client) {
    int team = GetClientTeam(client);
    SetEntityRenderMode(client, RENDER_GLOW);
    if (team == 2) {
        SetEntityRenderColor(client, 255, 30, 30, 255); // T = Bright Red
    } else if (team == 3) {
        SetEntityRenderColor(client, 30, 150, 255, 255); // CT = Bright Blue
    }
}

public void ApplyWeaponEffects(int client) {
    int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if (weapon > 0 && IsValidEntity(weapon)) {
        SetEntityRenderMode(weapon, RENDER_GLOW);
        SetEntityRenderColor(weapon, 255, 215, 0, 255); // GOLD
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));
    
    if (attacker > 0 && attacker != victim && IsClientInGame(attacker)) {
        ClientCommand(attacker, "play buttons/arena_switch_press_02.wav");
    }
    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker > 0 && attacker != victim && IsClientInGame(attacker)) {
        ClientCommand(attacker, "play physics/flesh/flesh_impact_bullet1.wav");
    }
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
            ApplyPlayerEffects(i);
            ApplyWeaponEffects(i);
        }
    }
    return Plugin_Continue;
}
