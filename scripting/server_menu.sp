/*
 * Server Menu for Counter-Strike: Source (v34)
 *
 * In-game menu opened with:  !smenu   (or sm_smenu in console)
 *
 * Menu items:
 * VIP - shows VIP perks (buy from server admin)
 * ﺭﻭﺮﺳ ﻦﯿﻧﺍﻮﻗ - server rules (edit RULES below before compiling)
 * ﺕﺍﺭﻮﺘﺳﺩ VIP - only visible to VIPs (flag "o")
 *  ﺭﻭﺮﺳ ﺕﺎﻋﻼﻃﺍ  - map, players, timeleft
 *
 * Install:
 *  1. Edit RULES / convar defaults below if you want
 *  2. Compile with spcomp -> server_menu.smx
 *  3. Put server_menu.smx in: cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// ---------------- edit your rules here ----------------
char g_Rules[][] = {
    "1. ﻉﻮﻨﻤﻣ ﺎﻫﺮﯿﻠﭘ ﻪﺑ ﻦﯿﻫﻮﺗ ﻭ ﯽﺷﺎﺤﻓ",
    "2. ﻉﻮﻨﻤﻣ ﮒﺎﺑ ﺯﺍ ﻩﺩﺎﻔﺘﺳﺍﺀﻮﺳ ﻭ ﺖﭙﯾﺮﮑﺳﺍ ,ﺖﯿﭼ",
    "3. ﻉﻮﻨﻤﻣ ﺖﭼ ﻭ ﻥﻮﻓﻭﺮﮑﯿﻣ ﻢﭙﺳﺍ",
    "4. ﻉﻮﻨﻤﻣ ﻒﯾﺮﺣ ﻥﻭﺎﭙﺳﺍ ﺖﺸﭘ ﻥﺩﺮﮐ ﭗﻤﮐ",
    "5. ﺭﺍﺬﺑ ﻡﺍﺮﺘﺣﺍ ﺎﻫﻦﯿﻣﺩﺍ ﻪﺑ"
};
// ------------------------------------------------------

ConVar g_cvTag;

public Plugin myinfo =
{
    name        = "Server Menu",
    author      = "Server Owner",
    description = "Cool in-game server menu: rules, info, VIP commands",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_smenu", Cmd_Menu, "Open the server menu");

    g_cvTag = CreateConVar("sm_menu_tag", "[VIP]", "Chat prefix for menu messages");

    AutoExecConfig(true, "server_menu");
}

public void OnClientPutInServer(int client)
{
    // friendly hint a few seconds after joining
    CreateTimer(12.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Welcome(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        char tag[32];
        g_cvTag.GetString(tag, sizeof(tag));
        PrintToChat(client, "%s ﺲﯾﻮﻨﺑ ﺖﭼ ﯼﻮﺗ ﺭﻭﺮﺳ ﯼﻮﻨﻣ ﻥﺪﯾﺩ ﯼﺍﺮﺑ: \x04!smenu", tag);
    }
    return Plugin_Stop;
}

public Action Cmd_Menu(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(0, "This command is in-game only.");
        return Plugin_Handled;
    }
    ShowMainMenu(client);
    return Plugin_Handled;
}

// ---------------- main menu ----------------
void ShowMainMenu(int client)
{
    Menu menu = new Menu(MainMenuHandler);
    menu.SetTitle(" ﺭﻭﺮﺳ ﯼﻮﻨﻣ\n ");
    menu.AddItem("rules", " ﺭﻭﺮﺳ ﻦﯿﻧﺍﻮﻗ");

    if (CheckCommandAccess(client, "sm_menu_vip", ADMFLAG_CUSTOM1))
        menu.AddItem("vipcmds", " ﺕﺍﺭﻮﺘﺳﺩ VIP");

    menu.AddItem("info", "ﺭﻭﺮﺳ ﺕﺎﻋﻼﻃﺍ");
    menu.ExitButton = true;
    menu.Display(client, 30);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "vip"))
            ShowVipInfo(client);
        else if (StrEqual(info, "rules"))
            ShowRules(client);
        else if (StrEqual(info, "vipcmds"))
            ShowVipCmds(client);
        else if (StrEqual(info, "info"))
            ShowInfo(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ---------------- VIP info ----------------
void ShowVipInfo(int client)
{
    char tag[32];
    g_cvTag.GetString(tag, sizeof(tag));

    PrintToChat(client, "%s  \x04VIP ﺭﻭﺮﺳ", tag);
    PrintToChat(client, "%s ﺕﺎﻧﺎﮑﻣﺍ:", tag);
    PrintToChat(client, "    noclip ﺭﻮﺘﺳﺩ ﺎﺑ \x04!vn", tag);
    PrintToChat(client, "    godmode ﺭﻮﺘﺳﺩ ﺎﺑ \x04!vg", tag);
    PrintToChat(client, "    ﺭﻮﺘﺳﺩ ﺎﺑ ﺎﻫﻪﺤﻠﺳﺍ ﯼﻪﻤﻫ \x04!vw", tag);
}

// ---------------- rules ----------------
void ShowRules(int client)
{
    Menu menu = new Menu(SubMenuHandler);
    menu.SetTitle(" ﺭﻭﺮﺳ ﻦﯿﻧﺍﻮﻗ\n ");

    char item[128];
    for (int i = 0; i < sizeof(g_Rules); i++)
    {
        Format(item, sizeof(item), "%s", g_Rules[i]);
        menu.AddItem("", item, ITEMDRAW_DISABLED);
    }

    menu.AddItem("back", " ﺖﺸﮔﺯﺎﺑ");
    menu.ExitButton = false;
    menu.Display(client, 30);
}

// ---------------- VIP commands ----------------
void ShowVipCmds(int client)
{
    Menu menu = new Menu(SubMenuHandler);
    menu.SetTitle(" ﺕﺍﺭﻮﺘﺳﺩ VIP\n ");

    menu.AddItem("", "!vn  (ﺎﯾ sm_vn) — ﻦﺷﻭﺭ/ﺵﻮﻣﺎﺧ noclip", ITEMDRAW_DISABLED);
    menu.AddItem("", "!vg  (ﺎﯾ sm_vg) — ﻦﺷﻭﺭ/ﺵﻮﻣﺎﺧ godmode", ITEMDRAW_DISABLED);
    menu.AddItem("", "!vw  (ﺎﯾ sm_vw) — ﺎﻫﻪﺤﻠﺳﺍ ﯼﻪﻤﻫ ﻦﺘﻓﺮﮔ", ITEMDRAW_DISABLED);

    menu.AddItem("back", " ﺖﺸﮔﺯﺎﺑ");
    menu.ExitButton = false;
    menu.Display(client, 30);
}

// ---------------- server info ----------------
void ShowInfo(int client)
{
    char tag[32], map[64];
    g_cvTag.GetString(tag, sizeof(tag));
    GetCurrentMap(map, sizeof(map));

    int players = 0, max = GetMaxClients();
    for (int i = 1; i <= max; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            players++;

    PrintToChat(client, "%s ﯽﻠﻌﻓ ﭗﻣ: \x04%s", tag, map);
    PrintToChat(client, "%s  ﺎﻫﺮﯿﻠﭘ: \x04%d\x01 ﺯﺍ %d", tag, players, max);

    int timeleft;
    if (GetMapTimeLeft(timeleft) && timeleft > 0)
        PrintToChat(client, "%s ﭗﻣ ﻩﺪﻧﺎﻣﯽﻗﺎﺑ ﻥﺎﻣﺯ: \x04%d\x01 ﻪﻘﯿﻗﺩ", tag, timeleft / 60);
}

public int SubMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        if (StrEqual(info, "back"))
            ShowMainMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}
