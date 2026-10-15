/*
 * Server Menu for Counter-Strike: Source (v34)
 *
 * In-game menu opened with:  !smenu   (or sm_smenu in console)
 *
 * Menu items:
 *   💎 VIP          - shows VIP perks (buy from server admin)
 *   📜 قوانین سرور   - server rules (edit RULES below before compiling)
 *   ⚡ دستورات VIP   - only visible to VIPs (flag "o")
 *   ℹ️ اطلاعات سرور  - map, players, timeleft
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
    "1. فحاشی و توهین به پلیرها ممنوع",
    "2. چیت، اسکریپت و سوءاستفاده از باگ ممنوع",
    "3. اسپم میکروفون و چت ممنوع",
    "4. کمپ کردن پشت اسپاون حریف ممنوع",
    "5. به ادمین‌ها احترام بذار"
};
// ------------------------------------------------------

ConVar g_cvTag;

public Plugin myinfo =
{
    name        = "Server Menu",
    author      = "Server Owner",
    description = "Cool in-game server menu: VIP shop, rules, info",
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
        PrintToChat(client, "%s برای دیدن منوی سرور توی چت بنویس: \x04!smenu", tag);
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
    menu.SetTitle("🎮 منوی سرور\n ");
    menu.AddItem("vip",   "💎 خرید VIP");
    menu.AddItem("rules", "📜 قوانین سرور");

    if (CheckCommandAccess(client, "sm_menu_vip", ADMFLAG_CUSTOM1))
        menu.AddItem("vipcmds", "⚡ دستورات VIP");

    menu.AddItem("info", "ℹ️ اطلاعات سرور");
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

    PrintToChat(client, "%s 💎 \x04VIP سرور", tag);
    PrintToChat(client, "%s امکانات:", tag);
    PrintToChat(client, "  ✈️  noclip با دستور \x04!vn", tag);
    PrintToChat(client, "  🛡️  godmode با دستور \x04!vg", tag);
    PrintToChat(client, "  🔫  همه‌ی اسلحه‌ها با دستور \x04!vw", tag);
    PrintToChat(client, "%s 📩 برای خرید VIP به ادمین سرور پیام بده", tag);
}

// ---------------- rules ----------------
void ShowRules(int client)
{
    Menu menu = new Menu(SubMenuHandler);
    menu.SetTitle("📜 قوانین سرور\n ");

    char item[128];
    for (int i = 0; i < sizeof(g_Rules); i++)
    {
        Format(item, sizeof(item), "%s", g_Rules[i]);
        menu.AddItem("", item, ITEMDRAW_DISABLED);
    }

    menu.AddItem("back", "🔙 بازگشت");
    menu.ExitButton = false;
    menu.Display(client, 30);
}

// ---------------- VIP commands ----------------
void ShowVipCmds(int client)
{
    Menu menu = new Menu(SubMenuHandler);
    menu.SetTitle("⚡ دستورات VIP\n ");

    menu.AddItem("", "!vn  (یا sm_vn) — روشن/خاموش noclip", ITEMDRAW_DISABLED);
    menu.AddItem("", "!vg  (یا sm_vg) — روشن/خاموش godmode", ITEMDRAW_DISABLED);
    menu.AddItem("", "!vw  (یا sm_vw) — گرفتن همه‌ی اسلحه‌ها", ITEMDRAW_DISABLED);

    menu.AddItem("back", "🔙 بازگشت");
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

    PrintToChat(client, "%s ℹ️ مپ فعلی: \x04%s", tag, map);
    PrintToChat(client, "%s 👥 پلیرها: \x04%d\x01 از %d", tag, players, max);

    int timeleft;
    if (GetMapTimeLeft(timeleft) && timeleft > 0)
        PrintToChat(client, "%s ⏱️ زمان باقی‌مانده مپ: \x04%d\x01 دقیقه", tag, timeleft / 60);
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
