#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/*
 * Wh1Tes Modes v0.1 (DRAFT — compile with SourceMod 1.9, test on server before calling it done)
 *
 * Admin-only game-mode switcher. Admin binds a key:  bind j "sm_mode"
 * Opens a menu; picking a mode applies it instantly (cvars set from inside the
 * plugin — exec'ing cfg files garbles in this build) + round restart + center text.
 *
 * Modes: 0 Classic | 1 Match | 2 Headshot only | 3 Knife+HE | 4 Pistols | 5 AWP | 6 ScoutzKnivez
 * Coordination: sets wh1tes_maxmoney (Wh1Tes Round Money cvar) 1 only in Classic.
 * Classic has 5s freezetime (Ali's call). Match: team-only voice via sv_alltalk 0,
 * toggle live with sm_teamvoice or wh1tes_teamvoice 0/1.
 * Restricted modes hand out the loadout at spawn (strip + give): no buying needed —
 * AWP mode = knife+AWP, Scoutz = knife+Scout, Pistols = knife+Deagle, Knife = knife+3xHE.
 */

#define MODE_CLASSIC   0
#define MODE_MATCH     1
#define MODE_HEADSHOT  2
#define MODE_KNIFE     3
#define MODE_PISTOL    4
#define MODE_AWP       5
#define MODE_SCOUTZ    6

int g_iMode = MODE_CLASSIC;

char g_sModeNames[][] = {
    "Classic",
    "Match Mode",
    "Headshot Only",
    "Knife + HE",
    "Pistols Only",
    "AWP Only",
    "ScoutzKnivez"
};

public Plugin myinfo = {
    name = "Wh1Tes Modes",
    author = "Wh1Tes",
    description = "Admin one-key game mode switcher (J menu)",
    version = "0.1.0",
    url = ""
};

ConVar g_cvTeamVoice;

public void OnPluginStart()
{
    RegAdminCmd("sm_mode", Cmd_ModeMenu, ADMFLAG_GENERIC, "Open the game mode menu");
    RegAdminCmd("sm_teamvoice", Cmd_TeamVoice, ADMFLAG_GENERIC, "Toggle match-mode team voice on/off");
    g_cvTeamVoice = CreateConVar("wh1tes_teamvoice", "1", "Match mode: 1 = team-only voice, 0 = alltalk stays on");
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Cmd_TeamVoice(int client, int args)
{
    bool now = !g_cvTeamVoice.BoolValue;
    g_cvTeamVoice.BoolValue = now;
    if (g_iMode == MODE_MATCH)
        SetCvar("sv_alltalk", now ? "0" : "1");
    ReplyToCommand(client, "[Wh1Tes] Match team voice: %s", now ? "ON" : "OFF");
    return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
    SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
}

public Action Cmd_ModeMenu(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_Modes);
    menu.SetTitle("Game Mode (current: %s)", g_sModeNames[g_iMode]);
    for (int i = 0; i < sizeof(g_sModeNames); i++)
        menu.AddItem(g_sModeNames[i], g_sModeNames[i]);
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_Modes(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
        ApplyMode(param2);
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}

void SetCvar(const char[] name, const char[] value)
{
    ConVar cv = FindConVar(name);
    if (cv != null)
        cv.SetString(value);
}

void ResetCommon()
{
    // defaults every mode starts from
    SetCvar("sv_gravity", "800");
    SetCvar("mp_friendlyfire", "0");
    SetCvar("mp_freezetime", "0");
    SetCvar("sv_alltalk", "1");
    SetCvar("wh1tes_maxmoney", "0");
}

void ApplyMode(int mode)
{
    g_iMode = mode;
    ResetCommon();

    switch (mode)
    {
        case MODE_CLASSIC:
        {
            SetCvar("mp_startmoney", "16000");
            SetCvar("mp_freezetime", "5");
            SetCvar("wh1tes_maxmoney", "1");
        }
        case MODE_MATCH:
        {
            SetCvar("mp_startmoney", "800");
            SetCvar("mp_freezetime", "6");
            SetCvar("mp_friendlyfire", "1");
            SetCvar("mp_maxrounds", "30");
            SetCvar("mp_roundtime", "2");
            SetCvar("mp_c4timer", "35");
            // team-only voice (CT can't hear T and vice versa) unless disabled
            if (g_cvTeamVoice.BoolValue)
                SetCvar("sv_alltalk", "0");
        }
        case MODE_HEADSHOT, MODE_KNIFE, MODE_PISTOL, MODE_AWP:
        {
            SetCvar("mp_startmoney", "16000");
            // wh1tes_maxmoney stays 0 here (set in ResetCommon): Round Money
            // plugin must not fight the restricted modes.
        }
        case MODE_SCOUTZ:
        {
            SetCvar("mp_startmoney", "16000");
            SetCvar("sv_gravity", "200");
        }
    }

    PrintCenterTextAll("MODE: %s", g_sModeNames[mode]);
    PrintToChatAll(" \x04[Wh1Tes]\x01 Game mode changed to \x04%s", g_sModeNames[mode]);
    ServerCommand("mp_restartgame 1");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // re-assert gravity for scoutz (in case another plugin/config touched it)
    if (g_iMode == MODE_SCOUTZ)
        SetCvar("sv_gravity", "200");
}

/* ---------- spawn loadouts for restricted modes ---------- */

void StripWeapons(int client)
{
    int wep;
    for (int slot = 0; slot <= 4; slot++)
    {
        while ((wep = GetPlayerWeaponSlot(client, slot)) != -1)
        {
            RemovePlayerItem(client, wep);
            AcceptEntityInput(wep, "Kill");
        }
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_iMode < MODE_KNIFE)
        return;
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    // small delay so the engine finishes the default spawn inventory first
    CreateTimer(0.2, Timer_GiveLoadout, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveLoadout(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    StripWeapons(client);
    GivePlayerItem(client, "weapon_knife");
    switch (g_iMode)
    {
        case MODE_AWP:    GivePlayerItem(client, "weapon_awp");
        case MODE_SCOUTZ: GivePlayerItem(client, "weapon_scout");
        case MODE_PISTOL: GivePlayerItem(client, "weapon_deagle");
        case MODE_KNIFE:
        {
            GivePlayerItem(client, "weapon_hegrenade");
            GivePlayerItem(client, "weapon_hegrenade");
            GivePlayerItem(client, "weapon_hegrenade");
        }
    }
    return Plugin_Stop;
}

/* ---------- weapon restrictions ---------- */

bool WeaponAllowed(const char[] cls)
{
    switch (g_iMode)
    {
        case MODE_KNIFE:
            return StrEqual(cls, "weapon_knife") || StrEqual(cls, "weapon_hegrenade");
        case MODE_PISTOL:
            return StrEqual(cls, "weapon_knife") || StrEqual(cls, "weapon_usp")
                || StrEqual(cls, "weapon_glock") || StrEqual(cls, "weapon_deagle")
                || StrEqual(cls, "weapon_elite") || StrEqual(cls, "weapon_fiveseven")
                || StrEqual(cls, "weapon_p228") || StrEqual(cls, "weapon_hegrenade")
                || StrEqual(cls, "weapon_flashbang") || StrEqual(cls, "weapon_smokegrenade");
        case MODE_AWP:
            return StrEqual(cls, "weapon_knife") || StrEqual(cls, "weapon_awp")
                || StrEqual(cls, "weapon_hegrenade") || StrEqual(cls, "weapon_flashbang")
                || StrEqual(cls, "weapon_smokegrenade");
        case MODE_SCOUTZ:
            return StrEqual(cls, "weapon_knife") || StrEqual(cls, "weapon_scout")
                || StrEqual(cls, "weapon_hegrenade") || StrEqual(cls, "weapon_flashbang")
                || StrEqual(cls, "weapon_smokegrenade");
    }
    return true;
}

public Action Hook_WeaponCanUse(int client, int weapon)
{
    if (g_iMode < MODE_KNIFE)  // classic/match/headshot: no restrictions
        return Plugin_Continue;
    char cls[48];
    if (!GetEdictClassname(weapon, cls, sizeof(cls)))
        return Plugin_Continue;
    return WeaponAllowed(cls) ? Plugin_Continue : Plugin_Handled;
}

/* ---------- headshot only ---------- */

public Action Hook_TraceAttack(int victim, int &attacker, int &inflictor,
                               float &damage, int &damagetype, int &ammotype,
                               int hitbox, int hitgroup)
{
    if (g_iMode == MODE_HEADSHOT && hitgroup != 1)  // 1 = head
        return Plugin_Handled;
    return Plugin_Continue;
}
