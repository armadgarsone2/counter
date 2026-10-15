/*
 * Admin Panel (!admin) v3.0 - rewritten per owner spec
 *
 * Main menu:
 *   1. دستورات پلیرها   2. دستورات سرور   3. دستورات رای‌گیری
 *   4. مدیریت بات‌ها     5. سوپر ادمین     7. تلپورت منو   8. تنظیمات خاص
 *
 * Provides native AP_HasCheatAccess(client) for the cheater menu (/cheat grants).
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "Admin Panel (!admin)",
    author = "Server Owner",
    description = "Full admin panel - rewritten",
    version = "3.0",
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
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnClientDisconnect(int client)
{
    g_iAction[client] = ACT_NONE;
    g_iFirstPick[client] = 0;
    g_bCheatGranted[client] = false;
    g_bBurning[client] = false;
    g_bMutedByPanel[client] = false;
}

bool IsUserAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, true)
        || GetUserAdmin(client) != INVALID_ADMIN_ID;
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
    if (StrEqual(text, "!admin", false) || StrEqual(text, "/admin", false)) {
        if (IsUserAdmin(client)) ShowMainMenu(client);
        else PrintToChat(client, "[Server] ادمین نیستی!");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && victim <= MaxClients && IsClientInGame(victim)) {
        GetClientAbsOrigin(victim, g_DeathPos[victim]);
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
    menu.SetTitle("پنل ادمین سرور:");
    menu.AddItem("players",  "1. دستورات پلیرها");
    menu.AddItem("server",   "2. دستورات سرور");
    menu.AddItem("vote",     "3. دستورات رای‌گیری");
    menu.AddItem("bots",     "4. مدیریت بات‌ها");
    menu.AddItem("super",    "5. سوپر ادمین");
    menu.AddItem("teleport", "7. تلپورت منو");
    menu.AddItem("settings", "8. تنظیمات خاص");
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
        case FLT_ALIVE:   menu.SetTitle("پلیر را انتخاب کن (زنده‌ها):");
        case FLT_DEAD:    menu.SetTitle("پلیر را انتخاب کن (مرده‌ها):");
        case FLT_BOTS:    menu.SetTitle("بات را انتخاب کن:");
        case FLT_BURNING: menu.SetTitle("پلیر در حال سوختن:");
        case FLT_MUTED:   menu.SetTitle("پلیر میوت/گگ شده:");
        case FLT_OPPTEAM: menu.SetTitle("پلیر تیم مقابل را انتخاب کن:");
        default:          menu.SetTitle("پلیر را انتخاب کن:");
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
        menu.AddItem("", "— لیست خالی —", ITEMDRAW_DISABLED);
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
        PrintToChat(client, "[Server] پلیر از سرور رفت.");
        return 0;
    }
    char tname[64];
    GetClientName(target, tname, sizeof(tname));
    int act = g_iAction[client];
    int tuid = StringToInt(info);

    switch (act) {
        case ACT_KICK: {
            ServerCommand("kickid %d \"Kicked by Admin\"", tuid);
            PrintToChatAll("[Server] %s کیک شد.", tname);
        }
        case ACT_BAN: {
            ServerCommand("banid 30 %d", tuid);
            ServerCommand("kickid %d \"Banned by Admin\"", tuid);
            PrintToChatAll("[Server] %s بن شد (30 دقیقه).", tname);
        }
        case ACT_MUTE: {
            ServerCommand("sm_mute \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s میوت شد (ویس).", tname);
        }
        case ACT_GAG: {
            ServerCommand("sm_gag \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s گگ شد (چت).", tname);
        }
        case ACT_SILENCE: {
            ServerCommand("sm_silence \"#%d\"", tuid);
            g_bMutedByPanel[target] = true;
            PrintToChatAll("[Server] %s سایلنت شد.", tname);
        }
        case ACT_UNMUTE: {
            ServerCommand("sm_unmute \"#%d\"", tuid);
            ServerCommand("sm_ungag \"#%d\"", tuid);
            g_bMutedByPanel[target] = false;
            PrintToChatAll("[Server] میوت %s برداشته شد.", tname);
        }
        case ACT_CHANGETEAM: {
            int team = GetClientTeam(target);
            if (team == 2) ChangeClientTeam(target, 3);
            else if (team == 3) ChangeClientTeam(target, 2);
            else PrintToChat(client, "[Server] پلیر توی تیم نیست.");
            PrintToChatAll("[Server] تیم %s عوض شد.", tname);
        }
        case ACT_EXCHANGE: {
            if (g_iFirstPick[client] == 0) {
                g_iFirstPick[client] = tuid;
                PrintToChat(client, "[Server] اول: %s — حالا از تیم مقابل انتخاب کن.", tname);
                ShowPlayerList(client, FLT_OPPTEAM);
            } else {
                int first = GetClientOfUserId(g_iFirstPick[client]);
                g_iFirstPick[client] = 0;
                if (first > 0 && IsClientInGame(first) && first != target) {
                    int team1 = GetClientTeam(first);
                    int team2 = GetClientTeam(target);
                    if (team1 >= 2 && team2 >= 2 && team1 != team2) {
                        ChangeClientTeam(first, team2);
                        ChangeClientTeam(target, team1);
                        char n1[64];
                        GetClientName(first, n1, sizeof(n1));
                        PrintToChatAll("[Server] %s و %s جا به جا شدن.", n1, tname);
                    } else PrintToChat(client, "[Server] هر دو باید توی تیم باشن.");
                } else PrintToChat(client, "[Server] انتخاب نامعتبر.");
            }
        }
        case ACT_BURN: {
            IgniteEntity(target, 15.0);
            g_bBurning[target] = true;
            PrintToChatAll("[Server] %s آتیش گرفت! 🔥", tname);
        }
        case ACT_KILLONE: {
            ForcePlayerSuicide(target);
            PrintToChatAll("[Server] %s کشته شد.", tname);
        }
        case ACT_RESPAWN: {
            CS_RespawnPlayer(target);
            TeleportEntity(target, g_DeathPos[target], NULL_VECTOR, NULL_VECTOR);
            PrintToChatAll("[Server] %s ری‌اسپاون شد.", tname);
        }
        case ACT_UNBURN: {
            ExtinguishEntity(target);
            g_bBurning[target] = false;
            PrintToChatAll("[Server] آتیش %s خاموش شد.", tname);
        }
        case ACT_GRANTCHEAT: {
            g_bCheatGranted[target] = true;
            PrintToChatAll("[Server] %s دسترسی چیت گرفت! ✅", tname);
            PrintToChat(target, "[Server] با دستور \x04/cheat \x01منوی چیت رو باز کن");
        }
        case ACT_TP_SAVED_ONE: {
            if (g_HasSavedLocation) {
                TeleportEntity(target, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] %s تلپورت شد.", tname);
            } else PrintToChat(client, "[Server] اول لوکیشن سیو کن!");
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
                PrintToChatAll("[Server] همه به %s تلپورت شدن.", tname);
            } else if (src == -2) {
                for (int i = 1; i <= MaxClients; i++)
                    if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
                        TeleportEntity(i, dest, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] بات‌ها تلپورت شدن.");
            } else if (src == -3) {
                for (int i = 1; i <= MaxClients; i++)
                    if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
                        TeleportEntity(i, dest, NULL_VECTOR, NULL_VECTOR);
                PrintToChat(client, "[Server] پلیرهای زنده تلپورت شدن.");
            } else {
                int srcc = GetClientOfUserId(src);
                if (srcc > 0 && IsClientInGame(srcc) && IsPlayerAlive(srcc)) {
                    TeleportEntity(srcc, dest, NULL_VECTOR, NULL_VECTOR);
                    char n1[64];
                    GetClientName(srcc, n1, sizeof(n1));
                    PrintToChat(client, "[Server] %s به %s تلپورت شد.", n1, tname);
                } else PrintToChat(client, "[Server] پلیر مبدا معتبر نیست.");
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
    menu.SetTitle("پلیر مقصد را انتخاب کن:");
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
    menu.SetTitle("1. دستورات پلیرها:");
    menu.AddItem("kick",      "1. کیک پلیر");
    menu.AddItem("ban",       "2. بن پلیر");
    menu.AddItem("mute_menu", "3. میوت کردن پلیر");
    menu.AddItem("changeteam","4. چنج تیم");
    menu.AddItem("exchange",  "6. اکسچنج پلیر");
    menu.AddItem("unmute",    "7. رفع میوت/گگ/سایلنت");
    menu.AddItem("back",      "<- برگشت");
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
    menu.SetTitle("میوت کردن:");
    menu.AddItem("mute",    "1. میوت کردن پلیر (ویس)");
    menu.AddItem("gag",     "2. گگ پلیر (چت)");
    menu.AddItem("silence", "3. سایلنت کردن پلیر (هر دو)");
    menu.AddItem("back",    "<- برگشت");
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
    menu.SetTitle("2. دستورات سرور:");
    menu.AddItem("map",     "1. چوز مپ");
    menu.AddItem("balance", "2. بلانس تیم");
    menu.AddItem("restart", "3. ری‌استارت گیم");
    menu.AddItem("swap",    "4. سواپ تیم");
    menu.AddItem("back",    "<- برگشت");
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
            PrintToChatAll("[Server] بازی ری‌استارت شد.");
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
    while (nt > nct + 1) { ChangeClientTeam(t[--nt], 3); nct++; }
    while (nct > nt + 1) { ChangeClientTeam(ct[--nct], 2); nt++; }
    PrintToChatAll("[Server] تیم‌ها بالانس شدن. (T:%d | CT:%d)", nt, nct);
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
    for (int i = 0; i < nt; i++) ChangeClientTeam(t[i], 3);
    for (int i = 0; i < nct; i++) ChangeClientTeam(ct[i], 2);
    PrintToChatAll("[Server] تیم‌ها سواپ شدن!");
}

public void ShowMapList(int client)
{
    Menu menu = new Menu(MapListHandler);
    menu.SetTitle("مپ را انتخاب کن:");
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
        PrintToChatAll("[Server] مپ عوض شد: %s", map);
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
    menu.SetTitle("3. دستورات رای‌گیری:");
    menu.AddItem("votemap", "1. رای‌گیری مپ");
    menu.AddItem("votekick", "2. رای‌گیری کیک");
    menu.AddItem("back", "<- برگشت");
    menu.Display(client, 30);
}

public int VoteHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        PrintToChat(client, "[Server] این بخش هنوز فعال نیست.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 4. BOTS ====================
public void ShowBotMenu(int client)
{
    Menu menu = new Menu(BotMenuHandler);
    menu.SetTitle("4. مدیریت بات‌ها:");
    menu.AddItem("add",      "1. اد بات");
    menu.AddItem("weapon",   "2. سلاح بات‌ها");
    menu.AddItem("diff",     "3. سطح بات‌ها");
    menu.AddItem("kickone",  "4. حذف بات خاص");
    menu.AddItem("kickall",  "5. حذف تمام بات‌ها");
    menu.AddItem("killall",  "6. کشتن تمام بات‌ها");
    menu.AddItem("back",     "<- برگشت");
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
            PrintToChatAll("[Server] تمام بات‌ها حذف شدن.");
        }
        else if (StrEqual(info, "killall")) {
            ServerCommand("bot_kill");
            PrintToChatAll("[Server] تمام بات‌ها کشته شدن.");
        }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotAddMenu(int client)
{
    Menu menu = new Menu(BotAddHandler);
    menu.SetTitle("اد بات:");
    menu.AddItem("random", "1. اد بات (رندوم)");
    menu.AddItem("ct",     "2. اد بات سی‌تی");
    menu.AddItem("t",      "3. اد بات ترور");
    menu.AddItem("back",   "<- برگشت");
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
        PrintToChat(client, "[Server] بات اضافه شد.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotWeaponMenu(int client)
{
    Menu menu = new Menu(BotWeaponHandler);
    menu.SetTitle("سلاح بات‌ها:");
    menu.AddItem("all",    "1. همه سلاح‌ها");
    menu.AddItem("knife",  "2. فقط چاقو");
    menu.AddItem("pistol", "3. فقط پیستول");
    menu.AddItem("sniper", "4. فقط اسنایپر");
    menu.AddItem("back",   "<- برگشت");
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
        PrintToChatAll("[Server] سلاح بات‌ها تنظیم شد.");
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotDiffMenu(int client)
{
    Menu menu = new Menu(BotDiffHandler);
    menu.SetTitle("سطح بات‌ها:");
    menu.AddItem("0", "1. ایزی");
    menu.AddItem("1", "2. نرمال");
    menu.AddItem("2", "3. هارد");
    menu.AddItem("3", "4. اکسپرت");
    menu.AddItem("back", "<- برگشت");
    menu.Display(client, 30);
}

public int BotDiffHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowBotMenu(client); return 0; }
        ServerCommand("bot_difficulty %s", info);
        char label[16];
        if (StrEqual(info, "0")) label = "ایزی";
        else if (StrEqual(info, "1")) label = "نرمال";
        else if (StrEqual(info, "2")) label = "هارد";
        else label = "اکسپرت";
        PrintToChatAll("[Server] سطح بات‌ها: %s", label);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowBotKickList(int client)
{
    Menu menu = new Menu(BotKickHandler);
    menu.SetTitle("بات را برای حذف انتخاب کن:");
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || !IsFakeClient(i)) continue;
        char name[64];
        GetClientName(i, name, sizeof(name));
        menu.AddItem(name, name);
        count++;
    }
    if (count == 0) menu.AddItem("", "— باتی نیست —", ITEMDRAW_DISABLED);
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
        PrintToChat(client, "[Server] بات %s حذف شد.", name);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

// ==================== 7. TELEPORT ====================
public void ShowTeleportMenu(int client)
{
    Menu menu = new Menu(TeleportMenuHandler);
    menu.SetTitle("7. تلپورت منو:");
    menu.AddItem("save",   "1. سیو لوکیشن");
    menu.AddItem("tosaved","2. تلپورت پلیر به سیو لوکیشن");
    menu.AddItem("p2p",    "3. تلپورت پلیر به پلیر");
    menu.AddItem("back",   "<- برگشت");
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
            PrintToChat(client, "[Server] لوکیشن سیو شد! ✅");
        }
        else if (StrEqual(info, "tosaved")) ShowTpSavedMenu(client);
        else if (StrEqual(info, "p2p")) ShowTpP2PSrcMenu(client);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowTpSavedMenu(int client)
{
    if (!g_HasSavedLocation) {
        PrintToChat(client, "[Server] اول با گزینه ۱ لوکیشن سیو کن!");
        ShowTeleportMenu(client);
        return;
    }
    Menu menu = new Menu(TpSavedHandler);
    menu.SetTitle("تلپورت به سیو لوکیشن:");
    menu.AddItem("all",   "1. آل پلیر (همه)");
    menu.AddItem("bots",  "2. بات‌ها");
    menu.AddItem("alive", "3. پلیرهای زنده");
    menu.AddItem("one",   "4. یه پلیر خاص...");
    menu.AddItem("back",  "<- برگشت");
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
            PrintToChatAll("[Server] همه به لوکیشن سیو شده تلپورت شدن.");
        }
        else if (StrEqual(info, "bots")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
                    TeleportEntity(i, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
            PrintToChat(client, "[Server] بات‌ها تلپورت شدن.");
        }
        else if (StrEqual(info, "alive")) {
            for (int i = 1; i <= MaxClients; i++)
                if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
                    TeleportEntity(i, g_SavedLocation, NULL_VECTOR, NULL_VECTOR);
            PrintToChat(client, "[Server] پلیرهای زنده تلپورت شدن.");
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
    menu.SetTitle("کیا تلپورت بشن؟ (مبدا)");
    menu.AddItem("-1", "1. ALL (همه)");
    menu.AddItem("-2", "2. bots (بات‌ها)");
    menu.AddItem("-3", "3. alive (زنده‌ها)");
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
    menu.SetTitle("8. تنظیمات خاص:");
    menu.AddItem("alltalk", "1. ALL TALK");
    menu.AddItem("ff",      "2. فرندلی فایر");
    menu.AddItem("ftime",   "3. فریز تایم (بازی بی‌نهایت)");
    menu.AddItem("burn",    "4. بورن پلیر");
    menu.AddItem("kill",    "5. پلیر دد");
    menu.AddItem("weapons", "6. جایگزینی سلاح همه");
    menu.AddItem("respawn", "7. ری‌اسپاون پلیر");
    menu.AddItem("sethp",   "8. ست HP");
    menu.AddItem("unburn",  "9. آن‌بورن پلیر");
    menu.AddItem("back",    "<- برگشت");
    menu.Display(client, 30);
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(itemNum, info, sizeof(info));
        if (StrEqual(info, "back")) { ShowMainMenu(client); return 0; }
        if (StrEqual(info, "alltalk")) {
            ConVar cv = FindConVar("sv_alltalk");
            bool on = (cv == null) || !cv.BoolValue;
            ServerCommand("sv_alltalk %d", on ? 1 : 0);
            PrintToChatAll("[Server] ALL TALK %s شد!", on ? "فعال" : "غیرفعال");
        }
        else if (StrEqual(info, "ff")) {
            ConVar cv = FindConVar("mp_friendlyfire");
            bool on = (cv == null) || !cv.BoolValue;
            ServerCommand("mp_friendlyfire %d", on ? 1 : 0);
            PrintToChatAll("[Server] فرندلی فایر %s شد!", on ? "فعال" : "غیرفعال");
        }
        else if (StrEqual(info, "ftime")) {
            ConVar cv = FindConVar("mp_timelimit");
            bool infinite = (cv != null && cv.IntValue == 0);
            if (infinite) {
                ServerCommand("mp_timelimit 30");
                PrintToChatAll("[Server] تایم بازی محدود شد (30 دقیقه).");
            } else {
                ServerCommand("mp_timelimit 0");
                PrintToChatAll("[Server] تایم بازی بی‌نهایت شد! ♾️");
            }
        }
        else if (StrEqual(info, "burn"))    { g_iAction[client] = ACT_BURN; ShowPlayerList(client, FLT_ALIVE); }
        else if (StrEqual(info, "kill"))    ShowKillMenu(client);
        else if (StrEqual(info, "weapons")) ShowWeaponList(client);
        else if (StrEqual(info, "respawn")) { g_iAction[client] = ACT_RESPAWN; ShowPlayerList(client, FLT_DEAD); }
        else if (StrEqual(info, "sethp"))   ShowHpMenu(client);
        else if (StrEqual(info, "unburn"))  { g_iAction[client] = ACT_UNBURN; ShowPlayerList(client, FLT_BURNING); }
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowKillMenu(int client)
{
    Menu menu = new Menu(KillMenuHandler);
    menu.SetTitle("پلیر دد:");
    menu.AddItem("all",  "1. آل پلیر (همه)");
    menu.AddItem("one",  "2. یه پلیر خاص...");
    menu.AddItem("back", "<- برگشت");
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
            PrintToChatAll("[Server] همه پلیرها کشته شدن! 💀");
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
    menu.SetTitle("سلاح جایگزین را انتخاب کن:");
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
            for (int slot = 0; slot < 5; slot++) {
                while ((w = GetPlayerWeaponSlot(i, slot)) != -1) {
                    RemovePlayerItem(i, w);
                    AcceptEntityInput(w, "Kill");
                }
            }
            GivePlayerItem(i, weapon);
        }
        PrintToChatAll("[Server] سلاح همه شد: %s 🔫", weapon[7]);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}

public void ShowHpMenu(int client)
{
    Menu menu = new Menu(HpMenuHandler);
    menu.SetTitle("HP همه پلیرها:");
    menu.AddItem("100",  "100");
    menu.AddItem("200",  "200");
    menu.AddItem("500",  "500");
    menu.AddItem("1000", "1000");
    menu.AddItem("5000", "5000");
    menu.AddItem("back", "<- برگشت");
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
        PrintToChatAll("[Server] HP همه شد: %d ❤️", hp);
    } else if (action == MenuAction_End) delete menu;
    return 0;
}
