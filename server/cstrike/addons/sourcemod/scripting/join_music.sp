/*
 * Join Music (fixed) for CS:S v34
 * Plays a random welcome song when a player connects, and STOPS it
 * as soon as they pick a team / spawn. (Fixes the "music keeps
 * playing after character select" bug.)
 *
 * Setup:
 *  1. mp3 files at: cstrike/sound/misc/welcome.mp3 (etc.)
 *     (change sm_joinmusic_files if yours are elsewhere)
 *  2. Make sure clients can download them:
 *     sv_allowdownload 1  (or put them on FastDL)
 *  3. Compile -> join_music.smx -> cstrike/addons/sourcemod/plugins/
 *  4. Disable the old buggy welcome_music.smx (rename to .disabled)
 *
 * Player command: !music  (toggle on/off for yourself)
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define MAX_TRACKS 8

ConVar g_cvFiles;
ConVar g_cvEnabled;
char   g_sTracks[MAX_TRACKS][PLATFORM_MAX_PATH];
int    g_iTrackCount = 0;
char   g_sPlaying[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
bool   g_bWantsMusic[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "Join Music",
    author      = "Server Owner",
    description = "Random welcome music that stops after team select (bug-free)",
    version     = "1.1.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvFiles   = CreateConVar("sm_joinmusic_files", "misc/welcome.mp3;misc/welcome2.mp3;misc/welcome3.mp3", "Sound paths under cstrike/sound/, separated by ;");
    g_cvEnabled = CreateConVar("sm_joinmusic_enabled", "1", "Enable join music", _, true, 0.0, true, 1.0);

    RegConsoleCmd("sm_music", Cmd_ToggleMusic, "Toggle join music for yourself");

    HookEvent("player_team",  Event_StopMusic, EventHookMode_Post);
    HookEvent("player_spawn", Event_StopMusic, EventHookMode_Post);

    AutoExecConfig(true, "join_music");
    CacheSounds();
}

public void OnConfigsExecuted()
{
    CacheSounds();
}

void CacheSounds()
{
    char list[512];
    g_cvFiles.GetString(list, sizeof(list));

    char tracks[MAX_TRACKS][PLATFORM_MAX_PATH];
    int count = ExplodeString(list, ";", tracks, MAX_TRACKS, PLATFORM_MAX_PATH);

    g_iTrackCount = 0;
    for (int i = 0; i < count && g_iTrackCount < MAX_TRACKS; i++)
    {
        TrimString(tracks[i]);
        if (!tracks[i][0])
            continue;

        strcopy(g_sTracks[g_iTrackCount], PLATFORM_MAX_PATH, tracks[i]);

        char fullPath[PLATFORM_MAX_PATH];
        Format(fullPath, sizeof(fullPath), "sound/%s", tracks[i]);
        if (FileExists(fullPath))
        {
            AddFileToDownloadsTable(fullPath);
            PrecacheSound(tracks[i], true);
            g_iTrackCount++;
        }
        else
        {
            LogError("[JoinMusic] file not found: %s", fullPath);
        }
    }
    LogMessage("[JoinMusic] cached %d track(s)", g_iTrackCount);
}

public void OnClientPutInServer(int client)
{
    g_bWantsMusic[client] = true;
    g_sPlaying[client][0] = '\0';
    if (g_cvEnabled.BoolValue && g_iTrackCount > 0)
        CreateTimer(4.0, Timer_PlayMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayMusic(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)
        && g_bWantsMusic[client] && g_cvEnabled.BoolValue
        && GetClientTeam(client) <= 1 && g_iTrackCount > 0) // still choosing team
    {
        int pick = GetRandomInt(0, g_iTrackCount - 1);
        strcopy(g_sPlaying[client], PLATFORM_MAX_PATH, g_sTracks[pick]);
        EmitSoundToClient(client, g_sTracks[pick], SOUND_FROM_PLAYER, SNDCHAN_AUTO);
        PrintToChat(client, "🎵 ﻪﺸﺨﭘ ﻝﺎﺣ ﺭﺩ ﺩﻭﺭﻭ ﮓﻨﻫﺁ — ﺎﺑ \x04!music\x01 ﻦﮐ ﺶﺷﻮﻣﺎﺧ");
    }
    return Plugin_Stop;
}

// stop the music the moment they pick a team or spawn -> fixes the bug
public void Event_StopMusic(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && g_sPlaying[client][0])
    {
        StopSound(client, SNDCHAN_AUTO, g_sPlaying[client]);
        g_sPlaying[client][0] = '\0';
    }
}

public void OnClientDisconnect(int client)
{
    g_bWantsMusic[client] = true;
    g_sPlaying[client][0] = '\0';
}

public Action Cmd_ToggleMusic(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;

    g_bWantsMusic[client] = !g_bWantsMusic[client];
    if (!g_bWantsMusic[client] && g_sPlaying[client][0])
    {
        StopSound(client, SNDCHAN_AUTO, g_sPlaying[client]);
        g_sPlaying[client][0] = '\0';
    }

    PrintToChat(client, "🎵 ﺩﻭﺭﻭ ﮓﻨﻫﺁ: %s", g_bWantsMusic[client] ? "ﻦﺷﻭﺭ ✅" : "ﺵﻮﻣﺎﺧ ❌");
    return Plugin_Handled;
}
