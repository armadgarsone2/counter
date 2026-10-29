/*
 * Quake Sounds for CS:S v34
 * Classic arena announcer: First Blood, Headshot, Double/Triple/Multi Kill,
 * Killing Spree, Rampage, Humiliation (knife kill).
 *
 * Sounds live in: cstrike/sound/quake/*.mp3  (auto-added to downloads)
 * Player command: !quake  (toggle sounds for yourself)
 *
 * Install: compile -> quake_sounds.smx -> cstrike/addons/sourcemod/plugins/
 *          copy sound/quake/*.mp3      -> cstrike/sound/quake/
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define MULTI_WINDOW 4.0   // seconds between kills to count as multi-kill
#define SPREE_KILLS  5     // kill streak for Killing Spree
#define RAMPAGE_KILLS 8    // kill streak for Rampage
#define DOMINATING_KILLS 11  // kill streak for Dominating
#define UNSTOPPABLE_KILLS 14 // kill streak for Unstoppable
#define GODLIKE_KILLS 17     // kill streak for Godlike
#define WICKEDSICK_KILLS 20  // kill streak for Wicked Sick

char g_sSounds[][] = {
    "quake/firstblood.mp3",
    "quake/headshot.mp3",
    "quake/doublekill.mp3",
    "quake/triplekill.mp3",
    "quake/multikill.mp3",
    "quake/killingspree.mp3",
    "quake/rampage.mp3",
    "quake/humiliation.mp3",
    "quake/dominating.mp3",
    "quake/unstoppable.mp3",
    "quake/godlike.mp3",
    "quake/wickedsick.mp3",
    "quake/ultrakill.mp3",
    "quake/monsterkill.mp3",
    "quake/ludicrouskill.mp3",
    "quake/holyshit.mp3"
};

ConVar g_cvEnabled;
bool   g_bQuake[MAXPLAYERS + 1];
int    g_iStreak[MAXPLAYERS + 1];
int    g_iMulti[MAXPLAYERS + 1];
float  g_fLastKill[MAXPLAYERS + 1];
bool   g_bFirstBloodDone;

public Plugin myinfo =
{
    name        = "Quake Sounds",
    author      = "Server Owner",
    description = "Arena announcer sounds (first blood, multikill, sprees...)",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvEnabled = CreateConVar("sm_quake_enabled", "1", "Enable quake sounds", _, true, 0.0, true, 1.0);
    RegConsoleCmd("sm_quake", Cmd_Toggle, "Toggle quake sounds for yourself");
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    AutoExecConfig(true, "quake_sounds");
    CacheSounds();
}

public void OnConfigsExecuted()
{
    CacheSounds();
}

void CacheSounds()
{
    char full[PLATFORM_MAX_PATH];
    for (int i = 0; i < sizeof(g_sSounds); i++)
    {
        Format(full, sizeof(full), "sound/%s", g_sSounds[i]);
        if (FileExists(full))
        {
            AddFileToDownloadsTable(full);
            PrecacheSound(g_sSounds[i], true);
        }
        else
            LogError("[Quake] missing sound: %s", full);
    }
}

public void OnClientPutInServer(int client)
{
    g_bQuake[client] = true;
    g_iStreak[client] = 0;
    g_iMulti[client] = 0;
    g_fLastKill[client] = 0.0;
}

public Action Cmd_Toggle(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    g_bQuake[client] = !g_bQuake[client];
    PrintToChat(client, " ﯼﺎﻫﺍﺪﺻ Quake: %s", g_bQuake[client] ? "ﻦﺷﻭﺭ " : "ﺵﻮﻣﺎﺧ ");
    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bFirstBloodDone = false;
}

void PlayToAll(const char[] sound)
{
    if (!g_cvEnabled.BoolValue)
        return;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i) && g_bQuake[i])
            EmitSoundToClient(i, sound);
}

void PlayToOne(int client, const char[] sound)
{
    if (!g_cvEnabled.BoolValue || !g_bQuake[client])
        return;
    EmitSoundToClient(client, sound);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim   = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim > 0 && victim <= MaxClients)
    {
        g_iStreak[victim] = 0;
        g_iMulti[victim] = 0;
    }

    if (attacker < 1 || attacker > MaxClients || attacker == victim
        || !IsClientInGame(attacker) || IsFakeClient(attacker))
        return;

    float now = GetGameTime();

    // ---- first blood ----
    if (!g_bFirstBloodDone)
    {
        g_bFirstBloodDone = true;
        PlayToAll("quake/firstblood.mp3");
        PrintToChatAll("\x04 First Blood! \x03%N", attacker);
    }

    // ---- multi-kill window ----
    if (now - g_fLastKill[attacker] <= MULTI_WINDOW)
        g_iMulti[attacker]++;
    else
        g_iMulti[attacker] = 1;
    g_fLastKill[attacker] = now;
    g_iStreak[attacker]++;

    char weapon[32];
    event.GetString("weapon", weapon, sizeof(weapon));
    bool knife = StrEqual(weapon, "knife");

    // ---- humiliation (knife) ----
    if (knife)
    {
        PlayToAll("quake/humiliation.mp3");
        PrintToChatAll("\x02 Humiliation! \x03%N \x01ﺩﺯ ﻮﻗﺎﭼ ﺎﺑ!", attacker);
        return; // knife kill skips the rest
    }

    // ---- headshot (personal) ----
    if (event.GetBool("headshot"))
        PlayToOne(attacker, "quake/headshot.mp3");

    // ---- multi kill ----
    if (g_iMulti[attacker] == 2)
    {
        PlayToAll("quake/doublekill.mp3");
        PrintToChatAll("\x04 Double Kill! \x03%N", attacker);
    }
    else if (g_iMulti[attacker] == 3)
    {
        PlayToAll("quake/triplekill.mp3");
        PrintToChatAll("\x04 Triple Kill! \x03%N", attacker);
    }
    else if (g_iMulti[attacker] == 4)
    {
        PlayToAll("quake/multikill.mp3");
        PrintToChatAll("\x04 MULTI KILL x%d! \x03%N", g_iMulti[attacker], attacker);
    }
    else if (g_iMulti[attacker] == 5)
    {
        PlayToAll("quake/ultrakill.mp3");
        PrintToChatAll("\x04 ULTRA KILL x%d! \x03%N", g_iMulti[attacker], attacker);
    }
    else if (g_iMulti[attacker] == 6)
    {
        PlayToAll("quake/monsterkill.mp3");
        PrintToChatAll("\x04 MONSTER KILL x%d! \x03%N", g_iMulti[attacker], attacker);
    }
    else if (g_iMulti[attacker] == 7)
    {
        PlayToAll("quake/ludicrouskill.mp3");
        PrintToChatAll("\x04 LUDICROUS KILL x%d! \x03%N", g_iMulti[attacker], attacker);
    }
    else if (g_iMulti[attacker] >= 8)
    {
        PlayToAll("quake/holyshit.mp3");
        PrintToChatAll("\x04 HOLY SHIT x%d! \x03%N", g_iMulti[attacker], attacker);
    }

    // ---- streaks ----
    if (g_iStreak[attacker] == SPREE_KILLS)
    {
        PlayToAll("quake/killingspree.mp3");
        PrintToChatAll("\x04 Killing Spree! \x03%N \x01(%d ﻢﻫ ﺮﺳ ﺖﺸﭘ ﻞﯿﮐ)", attacker, g_iStreak[attacker]);
    }
    else if (g_iStreak[attacker] == RAMPAGE_KILLS)
    {
        PlayToAll("quake/rampage.mp3");
        PrintToChatAll("\x04 RAMPAGE! \x03%N \x01(%d ﻢﻫ ﺮﺳ ﺖﺸﭘ ﻞﯿﮐ)", attacker, g_iStreak[attacker]);
    }
    else if (g_iStreak[attacker] == DOMINATING_KILLS)
    {
        PlayToAll("quake/dominating.mp3");
        PrintToChatAll("\x04 DOMINATING! \x03%N \x01(%d kills in a row)", attacker, g_iStreak[attacker]);
    }
    else if (g_iStreak[attacker] == UNSTOPPABLE_KILLS)
    {
        PlayToAll("quake/unstoppable.mp3");
        PrintToChatAll("\x04 UNSTOPPABLE! \x03%N \x01(%d kills in a row)", attacker, g_iStreak[attacker]);
    }
    else if (g_iStreak[attacker] == GODLIKE_KILLS)
    {
        PlayToAll("quake/godlike.mp3");
        PrintToChatAll("\x04 GODLIKE! \x03%N \x01(%d kills in a row)", attacker, g_iStreak[attacker]);
    }
    else if (g_iStreak[attacker] == WICKEDSICK_KILLS)
    {
        PlayToAll("quake/wickedsick.mp3");
        PrintToChatAll("\x04 WICKED SICK! \x03%N \x01(%d kills in a row)", attacker, g_iStreak[attacker]);
    }
}
