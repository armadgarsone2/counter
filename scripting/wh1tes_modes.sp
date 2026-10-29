#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

/*
 * Wh1Tes Modes v0.5.2 — compile with SourceMod 1.9, test on server before calling it done)
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
 *
 * v0.5.2 fixes: loadout strip no longer kills the player's C4 (slot 4 is the
 * bomb slot — restricted modes still play the plant/defuse objective normally);
 * Knife mode now actually grants 3 HE grenades (CS:S caps GivePlayerItem at 1,
 * so the extra two are set via direct ammo prop instead); loadout timer
 * re-checks the mode before stripping (mode-switch race); wh1tes_teamvoice now
 * applies live even when changed directly (not just via sm_teamvoice); SDKHooks
 * are now also applied to clients already connected at plugin (re)load.
 */

#define MODE_CLASSIC   0
#define MODE_MATCH     1
#define MODE_HEADSHOT  2
#define MODE_KNIFE     3
#define MODE_PISTOL    4
#define MODE_AWP       5
#define MODE_SCOUTZ    6

int g_iMode = MODE_CLASSIC;
int g_iHalfCT = 0;
int g_iHalfT = 0;
bool g_bSwapped = false;

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
    version = "0.5.2",
    url = ""
};

ConVar g_cvTeamVoice;
ConVar g_cvCurMode;

public void OnPluginStart()
{
    RegAdminCmd("sm_mode", Cmd_ModeMenu, ADMFLAG_GENERIC, "Open the game mode menu");
    RegAdminCmd("sm_teamvoice", Cmd_TeamVoice, ADMFLAG_GENERIC, "Toggle match-mode team voice on/off");
    RegServerCmd("sm_botmode", Cmd_BotMode, "Query/set game mode from the server console (Telegram bot)");
    g_cvTeamVoice = CreateConVar("wh1tes_teamvoice", "1", "Match mode: 1 = team-only voice, 0 = alltalk stays on");
    HookConVarChange(g_cvTeamVoice, OnTeamVoiceChanged);
    // read by wh1tes_killoverlay: match mode uses band-merged medal textures
    g_cvCurMode = CreateConVar("wh1tes_curmode", "0", "Current Wh1Tes mode index (set by ApplyMode)");
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_ScoreDeath, EventHookMode_Post);
    HookEvent("player_team", Event_ScoreRoster, EventHookMode_Post);
    HookEvent("player_disconnect", Event_ScoreRoster, EventHookMode_Post);
    // keep the match scoreboard permanently on screen (HUD hold 3.2s,
    // refreshed every 2s + on game events)
    CreateTimer(2.0, Timer_ScoreRefresh, _, TIMER_REPEAT);

    // hook any clients already connected in case this plugin gets reloaded
    // mid-map (sm plugins reload) — OnClientPutInServer only fires for
    // clients connecting AFTER this point, which would otherwise leave
    // already-connected players unrestricted / unfiltered
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
            SDKHook(i, SDKHook_TraceAttack, Hook_TraceAttack);
        }
    }
}

public void OnTeamVoiceChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    // applies live even if wh1tes_teamvoice is changed directly (console/cfg)
    // instead of via sm_teamvoice
    if (g_iMode == MODE_MATCH)
        SetCvar("sv_alltalk", convar.BoolValue ? "0" : "1");
}

public Action Timer_ScoreRefresh(Handle timer)
{
    ShowMatchScore();
    return Plugin_Continue;
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


public Action Cmd_BotMode(int args)
{
    if (args < 1)
    {
        ReplyToCommand(0, "BOTMODE %d %s", g_iMode, g_sModeNames[g_iMode]);
        return Plugin_Handled;
    }
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int idx = -1;
    if (arg[0] >= '0' && arg[0] <= '6' && arg[1] == '\0')
        idx = arg[0] - '0';
    else
    {
        for (int i = 0; i < sizeof(g_sModeNames); i++)
        {
            if (StrContains(g_sModeNames[i], arg, false) != -1)
            {
                idx = i;
                break;
            }
        }
    }
    if (idx < 0)
    {
        ReplyToCommand(0, "BOTMODE_ERROR unknown mode '%s'", arg);
        return Plugin_Handled;
    }
    ApplyMode(idx);
    ReplyToCommand(0, "BOTMODE_SET %d %s", idx, g_sModeNames[idx]);
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
    SetCvar("mp_forcecamera", "0");
    SetCvar("mp_freezetime", "0");
    SetCvar("mp_maxrounds", "0");
    SetCvar("sv_alltalk", "1");
    SetCvar("wh1tes_maxmoney", "0");
}

void ApplyMode(int mode)
{
    g_iMode = mode;
    g_cvCurMode.IntValue = mode;
    g_bSwapped = false;
    g_iHalfCT = 0;
    g_iHalfT = 0;
    if (mode != MODE_MATCH)
        ClearMatchScore();
    // wipe any screen overlay (medal / scoreboard band) — the kill
    // overlay plugin re-applies the right texture for the new mode on
    // the round restart below
    ClearAllOverlays();
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
            // anti-ghosting (Ali's call 2026-10-23): dead CT/T can only
            // spectate their OWN team in Match mode
            SetCvar("mp_forcecamera", "1");
            SetCvar("mp_maxrounds", "32");
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

void GetMatchTotals(int &teamA, int &teamB)
{
    int ct = GetTeamScore(3);
    int t = GetTeamScore(2);
    if (!g_bSwapped)
    {
        teamA = ct;
        teamB = t;
    }
    else
    {
        teamA = g_iHalfCT + (t - g_iHalfT);
        teamB = g_iHalfT + (ct - g_iHalfCT);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (g_iMode != MODE_MATCH)
    {
        return;
    }
    int ct = GetTeamScore(3);
    int t = GetTeamScore(2);
    int teamA, teamB;
    GetMatchTotals(teamA, teamB);
    if (!g_bSwapped && (ct + t) >= 16)
    {
        g_iHalfCT = ct;
        g_iHalfT = t;
        g_bSwapped = true;
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client))
            {
                continue;
            }
            int team = GetClientTeam(client);
            if (team == CS_TEAM_CT)
            {
                CS_SwitchTeam(client, CS_TEAM_T);
            }
            else if (team == CS_TEAM_T)
            {
                CS_SwitchTeam(client, CS_TEAM_CT);
            }
        }
        PrintCenterTextAll("HALFTIME! Teams swap sides! CT %d - %d T", ct, t);
        PrintToChatAll(" \x04[Wh1Tes]\x01 HALFTIME! Teams swap sides! CT %d - %d T", ct, t);
    }
    if ((ct + t) >= 32)
    {
        // Full 32 rounds always played: no early win. Winner by total,
        // announced by current side; 16-16 is a draw.
        int ctTotal = g_bSwapped ? teamB : teamA;
        int tTotal = g_bSwapped ? teamA : teamB;
        if (ctTotal == tTotal)
        {
            PrintCenterTextAll("MATCH DRAW! 16 - 16");
            PrintToChatAll(" \x04[Wh1Tes]\x01 MATCH DRAW! CT 16 - 16 T");
        }
        else if (ctTotal > tTotal)
        {
            PrintCenterTextAll("MATCH OVER! Counter-Terrorists win %d - %d", ctTotal, tTotal);
            PrintToChatAll(" \x04[Wh1Tes]\x01 MATCH OVER! Counter-Terrorists win! CT %d - %d T", ctTotal, tTotal);
        }
        else
        {
            PrintCenterTextAll("MATCH OVER! Terrorists win %d - %d", tTotal, ctTotal);
            PrintToChatAll(" \x04[Wh1Tes]\x01 MATCH OVER! Terrorists win! CT %d - %d T", tTotal, ctTotal);
        }
        PrintToChatAll(" \x04[Wh1Tes]\x01 Match finished - returning to Classic mode...");
        CreateTimer(5.0, Timer_MatchEndClassic, _, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
}

/* Match-end: delay the Classic switch 5s so the MATCH OVER / DRAW center
 * text stays visible. It used to be overwritten in the same tick by
 * ApplyMode's own "MODE: Classic" center text, so the match seemed to end
 * silently. */
public Action Timer_MatchEndClassic(Handle timer)
{
    if (g_iMode == MODE_MATCH)
        ApplyMode(MODE_CLASSIC);
    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // re-assert gravity for scoutz (in case another plugin/config touched it)
    if (g_iMode == MODE_SCOUTZ)
        SetCvar("sv_gravity", "200");
    // match scoreboard: show once the round is set up
    if (g_iMode == MODE_MATCH)
        CreateTimer(1.0, Timer_ShowMatchScore, _, TIMER_FLAG_NO_MAPCHANGE);
}

/* ---------- match-mode scoreboard (Ali's call 2026-10-23) ----------
 * Match mode shows, as a persistent HUD text near the top: alive/total
 * players per team and rounds won per team. Refreshed every 2s, on
 * round start, on every death and on roster changes. */

public void Event_ScoreDeath(Event event, const char[] name, bool dontBroadcast)
{
    ShowMatchScore();
}

public void Event_ScoreRoster(Event event, const char[] name, bool dontBroadcast)
{
    if (g_iMode == MODE_MATCH)
        CreateTimer(0.5, Timer_ShowMatchScore, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ShowMatchScore(Handle timer)
{
    ShowMatchScore();
    return Plugin_Stop;
}

void ShowMatchScore()
{
    int teamA, teamB;
    GetMatchTotals(teamA, teamB);
    if (g_iMode != MODE_MATCH)
        return;
    int ctAlive = 0, ctTotal = 0, tAlive = 0, tTotal = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        int team = GetClientTeam(i);
        if (team == 3)
        {
            ctTotal++;
            if (IsPlayerAlive(i))
                ctAlive++;
        }
        else if (team == 2)
        {
            tTotal++;
            if (IsPlayerAlive(i))
                tAlive++;
        }
    }
    // HUD text near the top of the screen (Ali's call 2026-10-23: the
    // center-text version sat too low and faded). Channel 2 — proven
    // visible on this build by the wh1tes_hudprobe test he confirmed.
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        SetHudTextParams(-1.0, 0.09, 3.2, 255, 210, 90, 255, 0, 0.0, 0.1, 0.4);
        ShowHudText(i, 2, "CT %d/%d   |   T %d/%d\nRounds:  CT %d : %d T",
            ctAlive, ctTotal, tAlive, tTotal, (g_bSwapped ? teamB : teamA), (g_bSwapped ? teamA : teamB));
    }
}

void ClearMatchScore()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;
        SetHudTextParams(-1.0, 0.09, 0.1, 255, 210, 90, 255, 0, 0.0, 0.0, 0.0);
        ShowHudText(i, 2, "");
    }
}

void ClearAllOverlays()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            ClientCommand(i, "r_screenoverlay \"\"");
}

/* ---------- spawn loadouts for restricted modes ---------- */

void StripWeapons(int client)
{
    char cls[48];
    for (int slot = 0; slot <= 4; slot++)
    {
        int wep = GetPlayerWeaponSlot(client, slot);
        while (wep != -1)
        {
            // never strip the bomb: restricted modes (3-6) still play the
            // plant/defuse objective normally, only the loadout is restricted
            if (GetEdictClassname(wep, cls, sizeof(cls)) && StrEqual(cls, "weapon_c4"))
                break;

            RemovePlayerItem(client, wep);
            AcceptEntityInput(wep, "Kill");
            wep = GetPlayerWeaponSlot(client, slot);
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
    // mode may have changed in the 0.2s since spawn (e.g. admin switched
    // mode right after round start) — bail out so we don't strip a player
    // who is no longer in a restricted mode
    if (g_iMode < MODE_KNIFE)
        return Plugin_Stop;

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
            // CS:S caps HE grenade ammo at 1 per player, so calling
            // GivePlayerItem("weapon_hegrenade") 3 times only ever yields 1
            // nade. Give it once, then set the reserve ammo directly to 3.
            int nade = GivePlayerItem(client, "weapon_hegrenade");
            if (nade != -1)
            {
                int ammotype = GetEntProp(nade, Prop_Send, "m_iPrimaryAmmoType");
                if (ammotype > 0)
                    SetEntProp(client, Prop_Send, "m_iAmmo", 3, _, ammotype);
            }
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
