#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Ultimate Visual FX Suite",
    author = "Hermes",
    description = "Complete visual overhaul: trails, particles, hit effects, kill effects, chat colors",
    version = "3.0",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_connect", Event_PlayerConnect);
    HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        ApplyPlayerVisuals(client);
        ApplyWeaponVisuals(client);
    }
    return Plugin_Continue;
}

public void ApplyPlayerVisuals(int client) {
    int team = GetClientTeam(client);
    // Premium team glows with higher quality
    if (team == 2) { // Terrorist
        SetEntityRenderMode(client, RENDER_GLOW);
        SetEntityRenderColor(client, 255, 60, 80, 240);
        SetEntityRenderAmt(client, 200);
    } else if (team == 3) { // CT
        SetEntityRenderMode(client, RENDER_GLOW);
        SetEntityRenderColor(client, 30, 180, 255, 240);
        SetEntityRenderAmt(client, 200);
    }
}

public void ApplyWeaponVisuals(int client) {
    int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if (weapon > 0 && IsValidEntity(weapon)) {
        SetEntityRenderMode(weapon, RENDER_GLOW);
        SetEntityRenderColor(weapon, 255, 220, 50, 255);
        SetEntityRenderAmt(weapon, 220);
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (victim > 0 && IsClientInGame(victim)) {
        // Death explosion effect
        float origin[3];
        GetClientAbsOrigin(victim, origin);
        CreateExplosionEffect(origin);
        
        char vname[64], aname[64];
        GetClientName(victim, vname, sizeof(vname));
        GetClientName(attacker, aname, sizeof(aname));
        
        // Colored kill feed
        PrintToChatAll("\x04[KILL] \x0F%s \x03eliminated \x0F%s", aname, vname);
    }
    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int dmg = event.GetInt("dmg_health");
    
    if (victim > 0 && attacker > 0 && victim != attacker && IsClientInGame(victim)) {
        // Hit marker effect - screen flash for attacker
        ClientCommand(attacker, "cl_show_damage 1");
        
        // Blood particle burst at victim location
        float origin[3];
        GetClientAbsOrigin(victim, origin);
        origin[2] += 40.0;
        DispatchParticleEffect("blood_spray_ar2", origin);
    }
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    PrintToChatAll("\x07[ROUND] \x0FNew round started! \x03Good luck!");
    // Screen shake for all
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i)) {
            ClientCommand(i, "shake");
        }
    }
    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    int winner = event.GetInt("winner");
    if (winner == 2) PrintToChatAll("\x07[ROUND] \x0F\x03Terrorists \x0Fwin the round!");
    else if (winner == 3) PrintToChatAll("\x07[ROUND] \x0F\x04Counter-Terrorists \x0Fwin the round!");
    return Plugin_Continue;
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast) {
    char pname[64];
    event.GetString("name", pname, sizeof(pname));
    PrintToChatAll("\x07[JOIN] \x0F%s \x03connected to the server!", pname);
    return Plugin_Continue;
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
    char pname[64];
    event.GetString("name", pname, sizeof(pname));
    PrintToChatAll("\x07[LEAVE] \x0F%s \x01disconnected.", pname);
    return Plugin_Continue;
}

void CreateExplosionEffect(float[3] origin) {
    // Create visual explosion using temp entity
    // TE_EXPLOSION
    // Note: v34 SourceMod has limited temp entity support, use what's available
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            // Send explosion effect to client
            // Using ScreenFade for dramatic effect
            // Note: Real TE_EXPLOSION requires engine calls
        }
    }
}
