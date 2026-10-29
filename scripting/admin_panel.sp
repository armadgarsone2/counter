/*
 * Admin Panel (/PANEL1) v3.3 - rewritten per owner spec
 *
 * Main menu:
 *   1. ﺎﻫﺮﯿﻠﭘ ﺕﺍﺭﻮﺘﺳﺩ   2. ﺭﻭﺮﺳ ﺕﺍﺭﻮﺘﺳﺩ   3. ﯼﺮﯿﮔﯼﺍﺭ ﺕﺍﺭﻮﺘﺳﺩ
 *   4. ﺎﻫﺕﺎﺑ ﺖﯾﺮﯾﺪﻣ     5. ﻦﯿﻣﺩﺍ ﺮﭘﻮﺳ     6. ﻮﻨﻣ ﺕﺭﻮﭙﻠﺗ   7. ﺹﺎﺧ ﺕﺎﻤﯿﻈﻨﺗ
 *
 * Provides native AP_HasCheatAccess(client) for the cheater menu (/cheat grants).
 */

/* v3.3 fixes (arena review):
 * - "give weapon to all" strips only slots 0-2 now; grenades and C4 are left
 *   alone (was destroying the bomb entity).
 * - change-team no longer broadcasts a false success when the target is not
 *   on a team.
 * - Settings "Set HP" is now wired to ShowHpMenu (was dead).
 * - Invalid-target selection resets pending action/first-pick state.
 * - Saved teleport location is cleared on map change.
 * - Death-position respawn requires a valid same-map death (g_bHasDeathPos).
 * - Settings toggles use cached engine convars (wh1tes_bots_manual is still
 *   looked up lazily, load order is not guaranteed).
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "Admin Panel (/PANEL1)",
    author = "Server Owner",
    description = "Full admin panel - rewritten",
    version = "3.3",
    url = ""
};

// ---------- action codes ----------
#define ACT_NONE        0
#define ACT_KICK        1
#define ACT_BAN         2
#define ACT_MUTE        3
#define ACT_GAG         4
#define ACT_SILENCE     5
#define ACT_CHANGETEAM  6
#define ACT_EXCHANGE    7
#define ACT_UNMUTE      8
#define ACT_BURN        9
#define ACT_KILLONE     10
#define ACT_RESPAWN     11
#define ACT_UNBURN      12
#define ACT_GRANTCHEAT  13
#define ACT_TP_SAVED_ONE 14
#define ACT_TP_P2P_SRC  15
#define ACT_TP_P2P_DST  16

// player-list filters
#define FLT_ALL      0
#define FLT_ALIVE    1
#define FLT_DEAD     2
#define FLT_BOTS     3
#define FLT_BURNING  4
#define FLT_MUTED    5
#define FLT_OPPTEAM  6   // opposite team of g_iFirstPick

int   g_iAction[MAXPLAYERS + 1];
int   g_iFirstPick[MAXPLAYERS + 1];   // userid, or -1/-2/-3 for ALL/bots/alive
float g_SavedLocation[3];
bool  g_HasSavedLocation;
bool  g_bCheatGranted[MAXPLAYERS + 1];
float g_DeathPos[MAXPLAYERS + 1][3];
bool  g_bBurning[MAXPLAYERS + 1];
bool  g_bMutedByPanel[MAXPLAYERS + 1];
bool g_bHasDeathPos[MAXPLAYERS + 1];
ConVar g_cvAllTalk;
ConVar g_cvFriendlyFire;
ConVar g_cvTimelimit;

char g_Weapons[][] = {
    "weapon_knife", "weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle",
    "weapon_fiveseven", "weapon_elite", "weapon_m3", "weapon_xm1014",
    "weapon_mac10", "weapon_tmp", "weapon_mp5navy", "weapon_ump45", "weapon_p90",
    "weapon_galil", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_sg552",
    "weapon_aug", "weapon_scout", "weapon_awp", "weapon_sg550", "weapon_g3sg1", "weapon_m249"
};

// ---------- native for cheater menu ----------
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("AP_HasCheatAccess", Native_HasCheatAccess);
    return APLRes_Success;
}

public int Native_HasCheatAccess(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        return 0;
    return g_bCheatGranted[client] ? 1 : 0;
}

// ---------- setup ----------
public void OnPluginStart()
{
    AddCommandListener(OnClientSay, "say");
    AddCommandListener(OnClientSay, "say_team");
    RegAdminCmd("sm_fapanel", Cmd_FaPanel, ADMFLAG_GENERIC, "Open Persian admin panel");
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    g_cvAllTalk = FindConVar("sv_alltalk");
    g_cvFriendlyFire = FindConVar("mp_friendlyfire");
    g_cvTimelimit = FindConVar("mp_timelimit");
}

public void OnClientDisconnect(int client)
{
    g_iAction[client] = ACT_NONE;
    g_iFirstPick[client] = 0;
    g_bCheatGranted[client] = false;
    g_bBurning[client] = false;
    g_bMutedByPanel[client] = false;
    g_bHasDeathPos[client] = false;
}

public void OnMapStart()
{
    g_HasSavedLocation = false;
    for (int i = 1; i <= MaxClients; i++)
        g_bHasDeathPos[i] = false;
}

bool IsUserAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, true)
        || GetUserAdmin(client) != INVALID_ADMIN_ID;
}

public Action Cmd_FaPanel(int client, int args)
{
    if (client == 0)
    {
        return Plugin_Handled;
    }
    if (IsUserAdmin(client)) ShowMainMenu(client);
    else PrintToChat(client, "[Server] ﯽﺘﺴﯿﻧ ﻦﯿﻣﺩﺍ!");
    return Plugin_Handled;
}

public Action OnClientSay(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Continue;
    char text[192];
    GetCmdArgString(text, sizeof(text));
    int len = strlen(text);
    if (len >= 2 && text[0] == '"' && text[len-1] == '"') {
        text[len-1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }
    TrimString(text);
    if (StrEqual(text, "/__panel_fa_never__", true)) {
        if (IsUserAdmin(client)) ShowMainMenu(client);
        else PrintToChat(client, "[Server] ﯽﺘﺴﯿﻧ ﻦﯿﻣﺩﺍ!");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && victim <= MaxClients && IsClientInGame(victim)) {
        GetClientAbsOrigin(victim, g_DeathPos[victim]);
        g_bHasDeathPos[victim] = true;
        g_bBurning[victim] = false;
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients)
        g_bBurning[client] = false;
}

// ==================== MAIN MENU ====================
public void ShowMainMenu(int client)
{
    Menu menu = new Menu(MainMenuHandler);
    menu.SetTitle("ﺭﻭﺮﺳ ﻦﯿﻣﺩﺍ ﻞﻨﭘ:");
    menu.AddItem("players",  "1. ﺎﻫﺮﯿﻠﭘ ﺕﺍﺭﻮﺘﺳﺩ");
    menu.AddItem("server",   "2. ﺭﻭﺮﺳ ﺕﺍﺭﻮﺘﺳﺩ");
    menu.AddItem("vote",     "3. ﯼﺮﯿﮔﯼﺍﺭ ﺕﺍﺭﻮﺘﺳﺩ");
    menu.AddItem("bots",     "4. ﺎﻫﺕﺎﺑ ﺖﯾﺮﯾﺪﻣ");
    menu.AddItem("super",    "5. ﻦﯿﻣﺩﺍ ﺮﭘﻮﺳ");
    menu.AddItem("teleport", "6. ﻮﻨﻣ ﺕﺭﻮﭙﻠﺗ");
    menu.AddItem("settings", "7. ﺹﺎﺧ ﺕﺎﻤﯿﻈﻨﺗ");
    menu.Display(client, 30);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "players"))       ShowPlayerMenu(client);
        else if (StrEqual(info, "server"))   ShowServerMenu(client);
        else if (StrEqual(info, "vote"))     ShowVoteMenu(client);
        else if (StrEqual(info, "bots"))     ShowBotMenu(client);
        else if (StrEqual(info, "super"))    { g_iAction[client] = ACT_GRANTCHEAT; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "teleport")) ShowTeleportMenu(client);
        else if (StrEqual(info, "settings")) ShowSettingsMenu(client);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== player list helper ====================
public void ShowPlayerList(int client, int filter)
{
    Menu menu = new Menu(PlayerListHandler);
    switch (filter) {
        case FLT_ALIVE:   menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﺮﯿﻠﭘ (ﺎﻫﻩﺪﻧﺯ):");
        case FLT_DEAD:    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﺮﯿﻠﭘ (ﺎﻫﻩﺩﺮﻣ):");
        case FLT_BOTS:    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﺕﺎﺑ:");
        case FLT_BURNING: menu.SetTitle("ﻦﺘﺧﻮﺳ ﻝﺎﺣ ﺭﺩ ﺮﯿﻠﭘ:");
        case FLT_MUTED:   menu.SetTitle("ﺕﻮﯿﻣ ﺮﯿﻠﭘ/ﻩﺪﺷ ﮓﮔ:");
        case FLT_OPPTEAM: menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﻞﺑﺎﻘﻣ ﻢﯿﺗ ﺮﯿﻠﭘ:");
        default:          menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﺮﯿﻠﭘ:");
    }

    int count = 0;
    int firstTeam = 0;
    if (filter == FLT_OPPTEAM) {
        int first = GetClientOfUserId(g_iFirstPick[client]);
        if (first > 0 && IsClientInGame(first))
            firstTeam = GetClientTeam(first);
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;
        bool ok = false;
        switch (filter) {
            case FLT_ALL:     ok = true;
            case FLT_ALIVE:   ok = IsPlayerAlive(i);
            case FLT_DEAD:    ok = !IsPlayerAlive(i) && GetClientTeam(i) >= 2;
            case FLT_BOTS:    ok = IsFakeClient(i);
            case FLT_BURNING: ok = g_bBurning[i] && IsPlayerAlive(i);
            case FLT_MUTED:   ok = g_bMutedByPanel[i];
            case FLT_OPPTEAM: ok = (firstTeam >= 2 && GetClientTeam(i) != firstTeam && GetClientTeam(i) >= 2 && i != GetClientOfUserId(g_iFirstPick[client]));
        }
        if (!ok) continue;
        char name[64], id[16];
        GetClientName(i, name, sizeof(name));
        IntToString(GetClientUserId(i), id, sizeof(id));
        menu.AddItem(id, name);
        count++;
    }
    if (count == 0)
        menu.AddItem("", "— ﯽﻟﺎﺧ ﺖﺴﯿﻟ —", ITEMDRAW_DISABLED);
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int PlayerListHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack) {
        GoBack(client);
        return 0;
    }
    if (action != MenuAction_Select) {
        if (action == MenuAction_End) delete menu;
        return 0;
    }
    char info[16];
    menu.GetItem(itemNum, info, sizeof(info));
    int target = GetClientOfUserId(StringToInt(info));
    if (target <= 0 || !IsClientInGame(target)) {
        PrintToChat(client, "[Server] ﺖﻓﺭ ﺭﻭﺮﺳ ﺯﺍ ﺮﯿﻠﭘ.");
        g_iAction[client] = ACT_NONE;
        g_iFirstPick[client] = 0;
        return 0;
    }
    char tname[64];
    GetClientName(target, tname, sizeof(tname));
    int act = g_iAction[client];
    int tuid = StringToInt(info);

    switch (act) {
        case ACT_KICK: {
            ServerCommand("kickid %d \"Kicked by Admin\"", tuid);
            PrintToChatAll("[Server] %s ﺪﺷ ﮏﯿﮐ.", tname);
        }
        case ACT_BAN: {
            ServerCommand("banid 30 %d", tuid);
            ServerCommand("kickid %d \"Banned by Admin\"", tuid);
            PrintToChatAll("[Server] %s ﺪﺷ ﻦﺑ (30 ﻪﻘﯿﻗﺩ).", tname);
        }
        case ACT_MUTE: {
            ServerCommand("sm_mute \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s ﺪﺷ ﺕﻮﯿﻣ (ﺲﯾﻭ).", tname);
        }
        case ACT_GAG: {
            ServerCommand("sm_gag \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s ﺪﺷ ﮓﮔ (ﺖﭼ).", tname);
        }
        case ACT_SILENCE: {
            ServerCommand("sm_silence \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s ﺪﺷ ﺖﻨﻠﯾﺎﺳ.", tname);
        }
        case ACT_UNMUTE: {
            ServerCommand("sm_unmute \"#%d\"", tuid);
            ServerCommand("sm_ungag \"#%d\"", tuid);
            g_bMutedByPanel[target] = false;
            PrintToChatAll("[Server] ﺕﻮﯿﻣ %s ﺪﺷ ﻪﺘﺷﺍﺩﺮﺑ.", tname);
        }
        case ACT_CHANGETEAM: {
            int team = GetClientTeam(target);
            if (team == 2) { CS_SwitchTeam(target, 3); PrintToChatAll("[Server] ﻢﯿﺗ %s ﺪﺷ ﺽﻮﻋ.", tname); }
            else if (team == 3) { CS_SwitchTeam(target, 2); PrintToChatAll("[Server] ﻢﯿﺗ %s ﺪﺷ ﺽﻮﻋ.", tname); }
            else PrintToChat(client, "[Server] ﺖﺴﯿﻧ ﻢﯿﺗ ﯼﻮﺗ ﺮﯿﻠﭘ.");
        }
        case ACT_EXCHANGE: {
            if (g_iFirstPick[client] == 0) {
                g_iFirstPick[client] = tuid;
                PrintToChat(client, "[Server] ﻝﻭﺍ: %s — ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﻞﺑﺎﻘﻣ ﻢﯿﺗ ﺯﺍ ﻻﺎﺣ.", tname);
                ShowPlayerList(client, FLT_OPPTEAM);
                return 0; // keep ACT_EXCHANGE for the second pick (trailing reset used to wipe it)
            } else {
                int first = GetClientOfUserId(g_iFirstPick[client]);
                g_iFirstPick[client] = 0;
                if (first > 0 && IsClientInGame(first) && first != target) {
                    int team1 = GetClientTeam(first);
                    int team2 = GetClientTeam(target);
                    if (team1 >= 2 && team2 >= 2 && team1 != team2) {
                        CS_SwitchTeam(first, team2);
                        CS_SwitchTeam(target, team1);
                        char n1[64];
                        GetClientName(first, n1, sizeof(n1));
                        PrintToChatAll("[Server] %s ﻭ %s ﻥﺪﺷ ﺎﺟ ﻪﺑ ﺎﺟ.", n1, tname);
                    } else PrintToChat(client, "[Server] ﻦﺷﺎﺑ ﻢﯿﺗ ﯼﻮﺗ ﺪﯾﺎﺑ ﻭﺩ ﺮﻫ.");
                } else PrintToChat(client, "[Server] ﺮﺒﺘﻌﻣﺎﻧ ﺏﺎﺨﺘﻧﺍ.");
            }
        }
        case ACT_BURN: {
            IgniteEntity(target, 15.0);
            g_bBurning[target] = true;
            PrintToChatAll("[Server] %s ﺖﻓﺮﮔ ﺶﯿﺗﺁ! ", tname);
        }
        case ACT_KILLONE: {
            ForcePlayerSuicide(target);
            PrintToChatAll("[Server] %s ﺪﺷ ﻪﺘﺸﮐ.", tname);
        }
        case ACT_RESPAWN: {
            CS_RespawnPlayer(target);
            if (g_bHasDeathPos[target])
                TeleportEntity(target, g_DeathPos[target], NULL_VECTOR, NULL_VECTOR);
            PrintToChatAll("[Server] %s ﺪﺷ ﻥﻭﺎﭙﺳﺍﯼﺭ.", tname);
        }
        case ACT_UNBURN: {
            ExtinguishEntity(target);
            g_bBurning[target] = false;
            PrintToChatAll("[Server] ﺶﯿﺗﺁ %s ﺪﺷ ﺵﻮﻣﺎﺧ.", tname);
        }
        case ACT_GRANTCHEAT: {
            g_bCheatGranted[target] = true;
            PrintToChatAll("[Server] %s ﺖﻓﺮﮔ ﺖﯿﭼ ﯽﺳﺮﺘﺳﺩ! ", tname);
            PrintToChat(target, "[Server] ﺭﻮﺘﺳﺩ ﺎﺑ \x04/cheat \x01ﻦﮐ ﺯﺎﺑ ﻭﺭ ﺖﯿﭼ ﯼﻮﻨﻣ");
        }
        case ACT_TP_SAVED_ONE: {
            if (g_HasSavedLocation) {
                TeleportEntity(target, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] %s ﺪﺷ ﺕﺭﻮﭙﻠﺗ.", tname);
            } else PrintToChat(client, "[Server] ﻦﮐ ﻮﯿﺳ ﻦﺸﯿﮐﻮﻟ ﻝﻭﺍ!");
        }
        case ACT_TP_P2P_SRC: {
            // info holds special picks or a userid
            g_iFirstPick[client] = tuid; // may be -1/-2/-3 or userid
            ShowDestPlayerList(client);
        }
        case ACT_TP_P2P_DST: {
            float dest[3];
            GetClientAbsOrigin(target, dest);
            int src = g_iFirstPick[client];
            if (src == -1) {
                for (int i = 1; i <= MaxClients; i++)
                    if (IsClientInGame(i) && IsPlayerAlive(i))
                        TeleportEntity(i, dest, NULL_VECTOR, NULL_VECTOR);
                PrintToChatAll("[Server] ﻪﺑ ﻪﻤﻫ %s ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ.", tname);
            } else if (src == -2) {
                for (int i = 1; i <= MaxClients; i++)
                    if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
                        TeleportEntity(i, dest, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ ﺎﻫﺕﺎﺑ.");
            } else if (src == -3) {
                for (int i = 1; i <= MaxClients; i++)
                    if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
                        TeleportEntity(i, dest, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ ﻩﺪﻧﺯ ﯼﺎﻫﺮﯿﻠﭘ.");
            } else {
                int srcc = GetClientOfUserId(src);
                if (srcc > 0 && IsClientInGame(srcc) && IsPlayerAlive(srcc)) {
                    TeleportEntity(srcc, dest, NULL_VECTOR, NULL_VECTOR);
                    char n1[64];
                    GetClientName(srcc, n1, sizeof(n1));
                    PrintToChat(client, "[Server] %s ﻪﺑ %s ﺪﺷ ﺕﺭﻮﭙﻠﺗ.", n1, tname);
                } else PrintToChat(client, "[Server] ﺖﺴﯿﻧ ﺮﺒﺘﻌﻣ ﺍﺪﺒﻣ ﺮﯿﻠﭘ.");
            }
            g_iFirstPick[client] = 0;
        }
    }
    g_iAction[client] = ACT_NONE;
    return 0;
}

void GoBack(int client)
{
    // back button from player list -> reopen relevant menu
    int act = g_iAction[client];
    g_iAction[client] = ACT_NONE;
    if (act == ACT_TP_SAVED_ONE || act == ACT_TP_P2P_SRC || act == ACT_TP_P2P_DST)
        ShowTeleportMenu(client);
    else if (act == ACT_BURN || act == ACT_KILLONE || act == ACT_RESPAWN || act == ACT_UNBURN)
        ShowSettingsMenu(client);
    else if (act == ACT_GRANTCHEAT)
        ShowMainMenu(client);
    else
        ShowPlayerMenu(client);
}

void ShowDestPlayerList(int client)
{
    g_iAction[client] = ACT_TP_P2P_DST;
    Menu menu = new Menu(PlayerListHandler);
    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﺪﺼﻘﻣ ﺮﯿﻠﭘ:");
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;
        char name[64], id[16];
        GetClientName(i, name, sizeof(name));
        IntToString(GetClientUserId(i), id, sizeof(id));
        menu.AddItem(id, name);
    }
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

// ==================== 1. PLAYER COMMANDS ====================
public void ShowPlayerMenu(int client)
{
    Menu menu = new Menu(PlayerMenuHandler);
    menu.SetTitle("1. ﺎﻫﺮﯿﻠﭘ ﺕﺍﺭﻮﺘﺳﺩ:");
    menu.AddItem("kick",      "1. ﺮﯿﻠﭘ ﮏﯿﮐ");
    menu.AddItem("ban",       "2. ﺮﯿﻠﭘ ﻦﺑ");
    menu.AddItem("mute_menu", "3. ﺮﯿﻠﭘ ﻥﺩﺮﮐ ﺕﻮﯿﻣ");
    menu.AddItem("changeteam","4. ﻢﯿﺗ ﺞﻨﭼ");
    menu.AddItem("exchange",  "5. ﺮﯿﻠﭘ ﺞﻨﭽﺴﮐﺍ");
    menu.AddItem("unmute",    "6. ﺕﻮﯿﻣ ﻊﻓﺭ/ﮓﮔ/ﺖﻨﻠﯾﺎﺳ");
    menu.AddItem("back",      "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int PlayerMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "kick"))       { g_iAction[client] = ACT_KICK; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "ban"))   { g_iAction[client] = ACT_BAN; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "mute_menu")) ShowMuteSubMenu(client);
        else if (StrEqual(info, "changeteam")) { g_iAction[client] = ACT_CHANGETEAM; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "exchange"))   { g_iAction[client] = ACT_EXCHANGE; g_iFirstPick[client] = 0; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "unmute"))     { g_iAction[client] = ACT_UNMUTE; ShowPlayerList(client, FLT_MUTED); }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowMuteSubMenu(int client)
{
    Menu menu = new Menu(MuteSubHandler);
    menu.SetTitle("ﻥﺩﺮﮐ ﺕﻮﯿﻣ:");
    menu.AddItem("mute",    "1. ﺮﯿﻠﭘ ﻥﺩﺮﮐ ﺕﻮﯿﻣ (ﺲﯾﻭ)");
    menu.AddItem("gag",     "2. ﺮﯿﻠﭘ ﮓﮔ (ﺖﭼ)");
    menu.AddItem("silence", "3. ﺮﯿﻠﭘ ﻥﺩﺮﮐ ﺖﻨﻠﯾﺎﺳ (ﻭﺩ ﺮﻫ)");
    menu.AddItem("back",    "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int MuteSubHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowPlayerMenu(client); return 0; }
        if (StrEqual(info, "mute"))         { g_iAction[client] = ACT_MUTE; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "gag"))     { g_iAction[client] = ACT_GAG; ShowPlayerList(client, FLT_ALL); }
        else if (StrEqual(info, "silence")) { g_iAction[client] = ACT_SILENCE; ShowPlayerList(client, FLT_ALL); }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 2. SERVER ====================
public void ShowServerMenu(int client)
{
    Menu menu = new Menu(ServerMenuHandler);
    menu.SetTitle("2. ﺭﻭﺮﺳ ﺕﺍﺭﻮﺘﺳﺩ:");
    menu.AddItem("map",     "1. ﭗﻣ ﺯﻮﭼ");
    menu.AddItem("balance", "2. ﻢﯿﺗ ﺲﻧﻼﺑ");
    menu.AddItem("restart", "3. ﻢﯿﮔ ﺕﺭﺎﺘﺳﺍﯼﺭ");
    menu.AddItem("swap",    "4. ﻢﯿﺗ ﭖﺍﻮﺳ");
    menu.AddItem("back",    "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int ServerMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "map")) ShowMapList(client);
        else if (StrEqual(info, "balance")) {
            BalanceTeams();
        }
        else if (StrEqual(info, "restart")) {
            ServerCommand("mp_restartgame 1");
            PrintToChatAll("[Server] ﺪﺷ ﺕﺭﺎﺘﺳﺍﯼﺭ ﯼﺯﺎﺑ.");
        }
        else if (StrEqual(info, "swap")) {
            SwapTeams();
        }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

void BalanceTeams()
{
    int t[32], ct[32], nt = 0, nct = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        int team = GetClientTeam(i);
        if (team == 2 && nt < 32) t[nt++] = i;
        else if (team == 3 && nct < 32) ct[nct++] = i;
    }
    while (nt > nct + 1) { CS_SwitchTeam(t[--nt], 3); nct++; }
    while (nct > nt + 1) { CS_SwitchTeam(ct[--nct], 2); nt++; }
    PrintToChatAll("[Server] ﻥﺪﺷ ﺲﻧﻻﺎﺑ ﺎﻫﻢﯿﺗ. (T:%d | CT:%d)", nt, nct);
}

void SwapTeams()
{
    int t[32], ct[32], nt = 0, nct = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;
        int team = GetClientTeam(i);
        if (team == 2 && nt < 32) t[nt++] = i;
        else if (team == 3 && nct < 32) ct[nct++] = i;
    }
    for (int i = 0; i < nt; i++) CS_SwitchTeam(t[i], 3);
    for (int i = 0; i < nct; i++) CS_SwitchTeam(ct[i], 2);
    PrintToChatAll("[Server] ﻥﺪﺷ ﭖﺍﻮﺳ ﺎﻫﻢﯿﺗ!");
}

public void ShowMapList(int client)
{
    Menu menu = new Menu(MapListHandler);
    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﭗﻣ:");
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "../../mapcycle.txt");
    int count = 0;
    File f = OpenFile(path, "r");
    if (f != null) {
        char line[64];
        while (!f.EndOfFile() && count < 60) {
            if (!f.ReadLine(line, sizeof(line))) break;
            TrimString(line);
            if (line[0] == '\0' || line[0] == '/' || line[0] == ';') continue;
            ReplaceString(line, sizeof(line), ".bsp", "");
            menu.AddItem(line, line);
            count++;
        }
        delete f;
    }
    if (count == 0) {
        char maps[][] = {"de_dust2", "de_inferno", "de_nuke", "de_train", "cs_office", "cs_italy"};
        for (int i = 0; i < sizeof(maps); i++) menu.AddItem(maps[i], maps[i]);
    }
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int MapListHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack) {
        ShowServerMenu(client);
        return 0;
    }
    if (action == MenuAction_Select) {
        char map[64];
        menu.GetItem(itemNum, map, sizeof(map));
        PrintToChatAll("[Server] ﺪﺷ ﺽﻮﻋ ﭗﻣ: %s", map);
        char cmd[96];
        Format(cmd, sizeof(cmd), "changelevel %s", map);
        ServerCommand("%s", cmd);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 3. VOTES (placeholder) ====================
public void ShowVoteMenu(int client)
{
    Menu menu = new Menu(VoteHandler);
    menu.SetTitle("3. ﯼﺮﯿﮔﯼﺍﺭ ﺕﺍﺭﻮﺘﺳﺩ:");
    menu.AddItem("votemap", "1. ﭗﻣ ﯼﺮﯿﮔﯼﺍﺭ");
    menu.AddItem("votekick", "2. ﮏﯿﮐ ﯼﺮﯿﮔﯼﺍﺭ");
    menu.AddItem("back", "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int VoteHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        PrintToChat(client, "[Server] ﺖﺴﯿﻧ ﻝﺎﻌﻓ ﺯﻮﻨﻫ ﺶﺨﺑ ﻦﯾﺍ.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

void SetBotManual(int target)
{
    ConVar cv = FindConVar("wh1tes_bots_manual");
    if (cv != null)
        cv.SetInt(target);
}

int CountBots()
{
    int n = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && IsFakeClient(i))
            n++;
    return n;
}

// ==================== 4. BOTS ====================
public void ShowBotMenu(int client)
{
    Menu menu = new Menu(BotMenuHandler);
    menu.SetTitle("4. ﺎﻫﺕﺎﺑ ﺖﯾﺮﯾﺪﻣ:");
    menu.AddItem("add",      "1. ﺕﺎﺑ ﺩﺍ");
    menu.AddItem("weapon",   "2. ﺎﻫﺕﺎﺑ ﺡﻼﺳ");
    menu.AddItem("diff",     "3. ﺎﻫﺕﺎﺑ ﺢﻄﺳ");
    menu.AddItem("kickone",  "4. ﺹﺎﺧ ﺕﺎﺑ ﻑﺬﺣ");
    menu.AddItem("kickall",  "5. ﺎﻫﺕﺎﺑ ﻡﺎﻤﺗ ﻑﺬﺣ");
    menu.AddItem("killall",  "6. ﺎﻫﺕﺎﺑ ﻡﺎﻤﺗ ﻦﺘﺸﮐ");
    menu.AddItem("back",     "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int BotMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "add")) ShowBotAddMenu(client);
        else if (StrEqual(info, "weapon")) ShowBotWeaponMenu(client);
        else if (StrEqual(info, "diff")) ShowBotDiffMenu(client);
        else if (StrEqual(info, "kickone")) { g_iAction[client] = 100; ShowBotKickList(client); }
        else if (StrEqual(info, "kickall")) {
            ServerCommand("bot_kick");
            SetBotManual(0);
            PrintToChatAll("[Server] ﻥﺪﺷ ﻑﺬﺣ ﺎﻫﺕﺎﺑ ﻡﺎﻤﺗ.");
        }
        else if (StrEqual(info, "killall")) {
            ServerCommand("bot_kill");
            PrintToChatAll("[Server] ﻥﺪﺷ ﻪﺘﺸﮐ ﺎﻫﺕﺎﺑ ﻡﺎﻤﺗ.");
        }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotAddMenu(int client)
{
    Menu menu = new Menu(BotAddHandler);
    menu.SetTitle("ﺕﺎﺑ ﺩﺍ:");
    menu.AddItem("random", "1. ﺕﺎﺑ ﺩﺍ (ﻡﻭﺪﻧﺭ)");
    menu.AddItem("ct",     "2. ﯽﺗﯽﺳ ﺕﺎﺑ ﺩﺍ");
    menu.AddItem("t",      "3. ﺭﻭﺮﺗ ﺕﺎﺑ ﺩﺍ");
    menu.AddItem("back",   "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int BotAddHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowBotMenu(client); return 0; }
        if (StrEqual(info, "random")) ServerCommand("bot_add");
        else if (StrEqual(info, "ct")) ServerCommand("bot_add_ct");
        else if (StrEqual(info, "t")) ServerCommand("bot_add_t");
        SetBotManual(CountBots() + 1);
        PrintToChat(client, "[Server] ﺪﺷ ﻪﻓﺎﺿﺍ ﺕﺎﺑ.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotWeaponMenu(int client)
{
    Menu menu = new Menu(BotWeaponHandler);
    menu.SetTitle("ﺎﻫﺕﺎﺑ ﺡﻼﺳ:");
    menu.AddItem("all",    "1. ﺎﻫﺡﻼﺳ ﻪﻤﻫ");
    menu.AddItem("knife",  "2. ﻮﻗﺎﭼ ﻂﻘﻓ");
    menu.AddItem("pistol", "3. ﻝﻮﺘﺴﯿﭘ ﻂﻘﻓ");
    menu.AddItem("sniper", "4. ﺮﭙﯾﺎﻨﺳﺍ ﻂﻘﻓ");
    menu.AddItem("back",   "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int BotWeaponHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowBotMenu(client); return 0; }
        ServerCommand("bot_knives_only 0; bot_pistols_only 0; bot_snipers_only 0; bot_all_weapons 1");
        if (StrEqual(info, "knife")) ServerCommand("bot_knives_only 1");
        else if (StrEqual(info, "pistol")) ServerCommand("bot_pistols_only 1");
        else if (StrEqual(info, "sniper")) ServerCommand("bot_snipers_only 1");
        PrintToChatAll("[Server] ﺪﺷ ﻢﯿﻈﻨﺗ ﺎﻫﺕﺎﺑ ﺡﻼﺳ.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotDiffMenu(int client)
{
    Menu menu = new Menu(BotDiffHandler);
    menu.SetTitle("ﺎﻫﺕﺎﺑ ﺢﻄﺳ:");
    menu.AddItem("0", "1. ﯼﺰﯾﺍ");
    menu.AddItem("1", "2. ﻝﺎﻣﺮﻧ");
    menu.AddItem("2", "3. ﺩﺭﺎﻫ");
    menu.AddItem("3", "4. ﺕﺮﭙﺴﮐﺍ");
    menu.AddItem("back", "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int BotDiffHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowBotMenu(client); return 0; }
        ServerCommand("bot_difficulty %s", info);
        char label[32];
        if (StrEqual(info, "0")) label = "ﯼﺰﯾﺍ";
        else if (StrEqual(info, "1")) label = "ﻝﺎﻣﺮﻧ";
        else if (StrEqual(info, "2")) label = "ﺩﺭﺎﻫ";
        else label = "ﺕﺮﭙﺴﮐﺍ";
        PrintToChatAll("[Server] ﺎﻫﺕﺎﺑ ﺢﻄﺳ: %s", label);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotKickList(int client)
{
    Menu menu = new Menu(BotKickHandler);
    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﻑﺬﺣ ﯼﺍﺮﺑ ﺍﺭ ﺕﺎﺑ:");
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || !IsFakeClient(i)) continue;
        char name[64];
        GetClientName(i, name, sizeof(name));
        menu.AddItem(name, name);
        count++;
    }
    if (count == 0) menu.AddItem("", "— ﺖﺴﯿﻧ ﯽﺗﺎﺑ —", ITEMDRAW_DISABLED);
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int BotKickHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack) {
        ShowBotMenu(client);
        return 0;
    }
    if (action == MenuAction_Select) {
        char name[64];
        menu.GetItem(itemNum, name, sizeof(name));
        ServerCommand("bot_kick \"%s\"", name);
        int target = CountBots() - 1;
        SetBotManual(target < 0 ? 0 : target);
        PrintToChat(client, "[Server] ﺕﺎﺑ %s ﺪﺷ ﻑﺬﺣ.", name);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 7. TELEPORT ====================
public void ShowTeleportMenu(int client)
{
    Menu menu = new Menu(TeleportMenuHandler);
    menu.SetTitle("7. ﻮﻨﻣ ﺕﺭﻮﭙﻠﺗ:");
    menu.AddItem("save",   "1. ﻦﺸﯿﮐﻮﻟ ﻮﯿﺳ");
    menu.AddItem("tosaved","2. ﻦﺸﯿﮐﻮﻟ ﻮﯿﺳ ﻪﺑ ﺮﯿﻠﭘ ﺕﺭﻮﭙﻠﺗ");
    menu.AddItem("p2p",    "3. ﺮﯿﻠﭘ ﻪﺑ ﺮﯿﻠﭘ ﺕﺭﻮﭙﻠﺗ");
    menu.AddItem("back",   "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int TeleportMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "save")) {
            GetClientAbsOrigin(client, g_SavedLocation);
            g_HasSavedLocation = true;
            PrintToChat(client, "[Server] ﺪﺷ ﻮﯿﺳ ﻦﺸﯿﮐﻮﻟ! ");
        }
        else if (StrEqual(info, "tosaved")) ShowTpSavedMenu(client);
        else if (StrEqual(info, "p2p")) ShowTpP2PSrcMenu(client);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowTpSavedMenu(int client)
{
    if (!g_HasSavedLocation) {
        PrintToChat(client, "[Server] ﻦﮐ ﻮﯿﺳ ﻦﺸﯿﮐﻮﻟ 1 ﻪﻨﯾﺰﮔ ﺎﺑ ﻝﻭﺍ!");
        ShowTeleportMenu(client);
        return;
    }
    Menu menu = new Menu(TpSavedHandler);
    menu.SetTitle("ﻦﺸﯿﮐﻮﻟ ﻮﯿﺳ ﻪﺑ ﺕﺭﻮﭙﻠﺗ:");
    menu.AddItem("all",   "1. ﺮﯿﻠﭘ ﻝﺁ (ﻪﻤﻫ)");
    menu.AddItem("bots",  "2. ﺎﻫﺕﺎﺑ");
    menu.AddItem("alive", "3. ﻩﺪﻧﺯ ﯼﺎﻫﺮﯿﻠﭘ");
    menu.AddItem("one",   "4. ﺹﺎﺧ ﺮﯿﻠﭘ ﻪﯾ...");
    menu.AddItem("back",  "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int TpSavedHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowTeleportMenu(client); return 0; }
        if (!g_HasSavedLocation) return 0;
        if (StrEqual(info, "all")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && IsPlayerAlive(i))
                    TeleportEntity(i, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
            PrintToChatAll("[Server] ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ ﻩﺪﺷ ﻮﯿﺳ ﻦﺸﯿﮐﻮﻟ ﻪﺑ ﻪﻤﻫ.");
        }
        else if (StrEqual(info, "bots")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
                    TeleportEntity(i, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
            PrintToChat(client, "[Server] ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ ﺎﻫﺕﺎﺑ.");
        }
        else if (StrEqual(info, "alive")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
                    TeleportEntity(i, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
            PrintToChat(client, "[Server] ﻥﺪﺷ ﺕﺭﻮﭙﻠﺗ ﻩﺪﻧﺯ ﯼﺎﻫﺮﯿﻠﭘ.");
        }
        else if (StrEqual(info, "one")) {
            g_iAction[client] = ACT_TP_SAVED_ONE;
            ShowPlayerList(client, FLT_ALL);
        }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowTpP2PSrcMenu(int client)
{
    Menu menu = new Menu(TpP2PSrcHandler);
    menu.SetTitle("?ﻦﺸﺑ ﺕﺭﻮﭙﻠﺗ ﺎﯿﮐ (ﺍﺪﺒﻣ)");
    menu.AddItem("-1", "1. ALL (ﻪﻤﻫ)");
    menu.AddItem("-2", "2. bots (ﺎﻫﺕﺎﺑ)");
    menu.AddItem("-3", "3. alive (ﺎﻫﻩﺪﻧﺯ)");
    // then individual players
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;
        char name[64], id[16];
        GetClientName(i, name, sizeof(name));
        IntToString(GetClientUserId(i), id, sizeof(id));
        menu.AddItem(id, name);
    }
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int TpP2PSrcHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack) {
        ShowTeleportMenu(client);
        return 0;
    }
    if (action == MenuAction_Select) {
        char info[16];
        menu.GetItem(itemNum, info, sizeof(info));
        g_iAction[client] = ACT_TP_P2P_SRC;
        // reuse PlayerListHandler logic: stash then show dest list
        g_iFirstPick[client] = StringToInt(info);
        ShowDestPlayerList(client);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 8. SETTINGS ====================
public void ShowSettingsMenu(int client)
{
    Menu menu = new Menu(SettingsMenuHandler);
    menu.SetTitle("8. ﺹﺎﺧ ﺕﺎﻤﯿﻈﻨﺗ:");
    menu.AddItem("alltalk", "1. ALL TALK");
    menu.AddItem("ff",      "2. ﺮﯾﺎﻓ ﯽﻟﺪﻧﺮﻓ");
    menu.AddItem("ftime",   "3. ﻢﯾﺎﺗ ﺰﯾﺮﻓ (ﺖﯾﺎﻬﻧﯽﺑ ﯼﺯﺎﺑ)");
    menu.AddItem("burn",    "4. ﺮﯿﻠﭘ ﻥﺭﻮﺑ");
    menu.AddItem("kill",    "5. ﺩﺩ ﺮﯿﻠﭘ");
    menu.AddItem("weapons", "6. ﻪﻤﻫ ﺡﻼﺳ ﯽﻨﯾﺰﮕﯾﺎﺟ");
    menu.AddItem("respawn", "7. ﺮﯿﻠﭘ ﻥﻭﺎﭙﺳﺍﯼﺭ");
    menu.AddItem("sethp",   "8. ﺖﺳ HP");
    menu.AddItem("unburn",  "9. ﺮﯿﻠﭘ ﻥﺭﻮﺑﻥﺁ");
    menu.AddItem("back",    "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "alltalk")) {
            bool on = (g_cvAllTalk == null) || !g_cvAllTalk.BoolValue;
            ServerCommand("sv_alltalk %d", on ? 1 : 0);
            PrintToChatAll("[Server] ALL TALK %s ﺪﺷ!", on ? "ﻝﺎﻌﻓ" : "ﻝﺎﻌﻓﺮﯿﻏ");
        }
        else if (StrEqual(info, "ff")) {
            bool on = (g_cvFriendlyFire == null) || !g_cvFriendlyFire.BoolValue;
            ServerCommand("mp_friendlyfire %d", on ? 1 : 0);
            PrintToChatAll("[Server] ﺮﯾﺎﻓ ﯽﻟﺪﻧﺮﻓ %s ﺪﺷ!", on ? "ﻝﺎﻌﻓ" : "ﻝﺎﻌﻓﺮﯿﻏ");
        }
        else if (StrEqual(info, "ftime")) {
            bool infinite = (g_cvTimelimit != null && g_cvTimelimit.IntValue == 0);
            if (infinite) {
                ServerCommand("mp_timelimit 30");
                PrintToChatAll("[Server] ﺪﺷ ﺩﻭﺪﺤﻣ ﯼﺯﺎﺑ ﻢﯾﺎﺗ (30 ﻪﻘﯿﻗﺩ).");
            } else {
                ServerCommand("mp_timelimit 0");
                PrintToChatAll("[Server] ﺪﺷ ﺖﯾﺎﻬﻧﯽﺑ ﯼﺯﺎﺑ ﻢﯾﺎﺗ! ");
            }
        }
        else if (StrEqual(info, "burn"))    { g_iAction[client] = ACT_BURN; ShowPlayerList(client, FLT_ALIVE); }
        else if (StrEqual(info, "kill"))    ShowKillMenu(client);
        else if (StrEqual(info, "weapons")) ShowWeaponList(client);
        else if (StrEqual(info, "respawn")) { g_iAction[client] = ACT_RESPAWN; ShowPlayerList(client, FLT_DEAD); }
        else if (StrEqual(info, "sethp"))   ShowHpMenu(client);
        else if (StrEqual(info, "sethp"))   ShowHpMenu(client);
        else if (StrEqual(info, "unburn"))  { g_iAction[client] = ACT_UNBURN; ShowPlayerList(client, FLT_BURNING); }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowKillMenu(int client)
{
    Menu menu = new Menu(KillMenuHandler);
    menu.SetTitle("ﺩﺩ ﺮﯿﻠﭘ:");
    menu.AddItem("all",  "1. ﺮﯿﻠﭘ ﻝﺁ (ﻪﻤﻫ)");
    menu.AddItem("one",  "2. ﺹﺎﺧ ﺮﯿﻠﭘ ﻪﯾ...");
    menu.AddItem("back", "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int KillMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowSettingsMenu(client); return 0; }
        if (StrEqual(info, "all")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
                    ForcePlayerSuicide(i);
            PrintToChatAll("[Server] ﻥﺪﺷ ﻪﺘﺸﮐ ﺎﻫﺮﯿﻠﭘ ﻪﻤﻫ! ");
        }
        else if (StrEqual(info, "one")) {
            g_iAction[client] = ACT_KILLONE;
            ShowPlayerList(client, FLT_ALIVE);
        }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowWeaponList(int client)
{
    Menu menu = new Menu(WeaponListHandler);
    menu.SetTitle("ﻦﮐ ﺏﺎﺨﺘﻧﺍ ﺍﺭ ﻦﯾﺰﮕﯾﺎﺟ ﺡﻼﺳ:");
    for (int i = 0; i < sizeof(g_Weapons); i++) {
        char label[32];
        strcopy(label, sizeof(label), g_Weapons[i][7]); // strip "weapon_"
        menu.AddItem(g_Weapons[i], label);
    }
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int WeaponListHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack) {
        ShowSettingsMenu(client);
        return 0;
    }
    if (action == MenuAction_Select) {
        char weapon[32];
        menu.GetItem(itemNum, weapon, sizeof(weapon));
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
            int w;
            for (int slot = 0; slot < 3; slot++) {
                while ((w = GetPlayerWeaponSlot(i, slot)) != -1) {
                    RemovePlayerItem(i, w);
                    AcceptEntityInput(w, "Kill");
                }
            }
            if (!StrEqual(weapon, "weapon_knife"))
                GivePlayerItem(i, "weapon_knife");
            GivePlayerItem(i, weapon);
        }
        PrintToChatAll("[Server] ﺪﺷ ﻪﻤﻫ ﺡﻼﺳ: %s ", weapon[7]);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowHpMenu(int client)
{
    Menu menu = new Menu(HpMenuHandler);
    menu.SetTitle("HP ﺎﻫﺮﯿﻠﭘ ﻪﻤﻫ:");
    menu.AddItem("100",  "100");
    menu.AddItem("200",  "200");
    menu.AddItem("500",  "500");
    menu.AddItem("1000", "1000");
    menu.AddItem("5000", "5000");
    menu.AddItem("back", "<- ﺖﺸﮔﺮﺑ");
    menu.Display(client, 30);
}

public int HpMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowSettingsMenu(client); return 0; }
        int hp = StringToInt(info);
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && IsPlayerAlive(i))
                SetEntityHealth(i, hp);
        PrintToChatAll("[Server] HP ﺪﺷ ﻪﻤﻫ: %d ", hp);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}
