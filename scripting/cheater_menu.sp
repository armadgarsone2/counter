#include <sourcemod>
#include <sdktools>

// Optional integration with admin_panel.smx: players granted cheat access
// via the admin panel can open this menu with /cheat
public SharedPlugin __pl_admin_panel =
{
    name = "admin_panel",
    file = "admin_panel.smx",
    required = 0
};

public void __pl_admin_panel_SetNTVOptional()
{
    MarkNativeAsOptional("AP_HasCheatAccess");
}

native bool AP_HasCheatAccess(int client);

public Plugin myinfo = {
    name = "Cheater Menu (!menu) - Infinite Nades Fixed",
    author = "Hermes",
    description = "Complete cheat menu with infinite nades toggle",
    version = "2.1",
    url = ""
};

bool g_CheatEnabled[MAXPLAYERS + 1][7]; // hp, esp, noclip, god, nade, wallhack, infinite_nades

public void OnPluginStart() {
    AddCommandListener(OnClientSay, "say");
    AddCommandListener(OnClientSay, "say_team");
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("weapon_fire", Event_WeaponFire);
}

bool IsUserCheater(int client) {
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, true) || GetUserAdmin(client) != INVALID_ADMIN_ID) {
        return true;
    }
    if (GetFeatureStatus(FeatureType_Native, "AP_HasCheatAccess") == FeatureStatus_Available
        && AP_HasCheatAccess(client)) {
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

    if (StrEqual(text, "!menu", false) || StrEqual(text, "/menu", false) || StrEqual(text, "/cheat", false)) {
        if (!IsUserCheater(client)) {
            PrintToChat(client, "[Server] You don't have permission to use this menu!");
            return Plugin_Handled;
        }
        ShowCheaterMenu(client);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void ShowCheaterMenu(int client) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
    Menu menu = new Menu(CheaterMenuHandler);
    menu.SetTitle("Cheater Menu:");
    menu.AddItem("hp", "1. Set HP to 1000");
    menu.AddItem("esp", "2. ESP / Wallhack (See through walls)");
    menu.AddItem("wallhack", "3. Wallhack (Glow players through walls)");
    menu.AddItem("noclip", "4. Noclip (Fly / Walk through walls)");
    menu.AddItem("god", "5. Godmode (Invincible)");
    menu.AddItem("nade", "6. Infinite Nades (Toggle ON/OFF)");
    menu.Display(client, 20);
}

public int CheaterMenuHandler(Menu menu, MenuAction action, int client, int itemNum) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        
        if (StrEqual(info, "hp")) {
            SetEntityHealth(client, 1000);
            PrintToChat(client, "[Cheat] HP set to 1000!");
        } else if (StrEqual(info, "esp")) {
            g_CheatEnabled[client][1] = !g_CheatEnabled[client][1];
            if (g_CheatEnabled[client][1]) {
                EnableESP(client);
                PrintToChat(client, "[Cheat] ESP/Wallhack ENABLED!");
            } else {
                DisableESP(client);
                PrintToChat(client, "[Cheat] ESP/Wallhack DISABLED!");
            }
        } else if (StrEqual(info, "wallhack")) {
            g_CheatEnabled[client][5] = !g_CheatEnabled[client][5];
            if (g_CheatEnabled[client][5]) {
                EnableWallhack(client);
                PrintToChat(client, "[Cheat] Wallhack (Glow) ENABLED!");
            } else {
                DisableWallhack(client);
                PrintToChat(client, "[Cheat] Wallhack (Glow) DISABLED!");
            }
        } else if (StrEqual(info, "noclip")) {
            int moveType = GetEntityMoveType(client);
            if (moveType == MOVETYPE_NOCLIP) {
                SetEntityMoveType(client, MOVETYPE_WALK);
                PrintToChat(client, "[Cheat] Noclip disabled.");
            } else {
                SetEntityMoveType(client, MOVETYPE_NOCLIP);
                PrintToChat(client, "[Cheat] Noclip enabled!");
            }
        } else if (StrEqual(info, "god")) {
            SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
            PrintToChat(client, "[Cheat] Godmode enabled!");
        } else if (StrEqual(info, "nade")) {
            g_CheatEnabled[client][6] = !g_CheatEnabled[client][6];
            if (g_CheatEnabled[client][6]) {
                GivePlayerItem(client, "weapon_hegrenade");
                GivePlayerItem(client, "weapon_flashbang");
                GivePlayerItem(client, "weapon_smokegrenade");
                PrintToChat(client, "[Cheat] Infinite Nades ENABLED!");
            } else {
                PrintToChat(client, "[Cheat] Infinite Nades DISABLED!");
            }
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public void EnableESP(int client) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && i != client && IsPlayerAlive(i)) {
            SetEntProp(i, Prop_Send, "m_iGlowIndex", 1, 1);
        }
    }
}

public void DisableESP(int client) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && i != client) {
            SetEntProp(i, Prop_Send, "m_iGlowIndex", 0, 1);
        }
    }
}

public void EnableWallhack(int client) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && i != client && IsPlayerAlive(i)) {
            int team = GetClientTeam(i);
            SetEntityRenderMode(i, RENDER_GLOW);
            if (team == 2) {
                SetEntityRenderColor(i, 255, 0, 0, 255);
            } else if (team == 3) {
                SetEntityRenderColor(i, 0, 255, 0, 255);
            }
        }
    }
}

public void DisableWallhack(int client) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && i != client) {
            SetEntityRenderMode(i, RENDER_NORMAL);
        }
    }
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        if (g_CheatEnabled[client][6]) {
            char weapon[64];
            event.GetString("weapon", weapon, sizeof(weapon));
            if (StrContains(weapon, "grenade", false) != -1 || StrContains(weapon, "flash", false) != -1 || StrContains(weapon, "smoke", false) != -1) {
                GivePlayerItem(client, weapon);
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
        if (g_CheatEnabled[client][1]) EnableESP(client);
        if (g_CheatEnabled[client][5]) EnableWallhack(client);
    }
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0) {
        for (int i = 0; i < 7; i++) g_CheatEnabled[victim][i] = false;
    }
    return Plugin_Continue;
}
