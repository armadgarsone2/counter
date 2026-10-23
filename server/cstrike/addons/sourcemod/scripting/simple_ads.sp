/*
 * Simple Ads for CS:S v34
 * Rotating colored chat advertisements, read from:
 *   cstrike/addons/sourcemod/configs/advertisements.txt
 *
 * Format (same as the classic Advertisements plugin):
 *   "Advertisements"
 *   {
 *       "1" { "type" "C"  "text" "{GREEN}hello {DEFAULT}world" }
 *       ...
 *   }
 * Color tags: {DEFAULT} {GREEN} {LIGHTGREEN} {RED} {OLIVE} {BLUE} {ORANGE}
 *
 * ConVars (cfg/sourcemod/simple_ads.cfg):
 *   sm_ads_interval  - seconds between ads (default 60)
 *   sm_ads_enabled   - 1/0
 *
 * Install: compile -> simple_ads.smx -> cstrike/addons/sourcemod/plugins/
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ArrayList g_Ads;
int       g_iNext = 0;
ConVar    g_cvInterval;
ConVar    g_cvEnabled;
Handle    g_hTimer = null;

public Plugin myinfo =
{
    name        = "Simple Ads",
    author      = "Server Owner",
    description = "Rotating colored chat advertisements",
    version     = "1.0.1",
    url         = ""
};

public void OnPluginStart()
{
    g_Ads = new ArrayList(256);
    g_cvInterval = CreateConVar("sm_ads_interval", "60", "Seconds between advertisements", _, true, 10.0);
    g_cvEnabled  = CreateConVar("sm_ads_enabled", "1", "Enable advertisements", _, true, 0.0, true, 1.0);
    g_cvInterval.AddChangeHook(OnCvarChanged);
    g_cvEnabled.AddChangeHook(OnCvarChanged);
    AutoExecConfig(true, "simple_ads");
}

public void OnMapStart()
{
    // The ad timer is TIMER_FLAG_NO_MAPCHANGE: the runtime kills it
    // during the map transition, leaving g_hTimer with a stale handle
    // that RestartTimer() would KillTimer() ("Invalid timer handle"
    // on every map change). By OnMapStart the old timer is gone —
    // drop the handle here.
    g_hTimer = null;
}

public void OnConfigsExecuted()
{
    LoadAds();
    RestartTimer();
}

public void OnCvarChanged(ConVar convar, const char[] oldV, const char[] newV)
{
    RestartTimer();
}

void LoadAds()
{
    g_Ads.Clear();
    g_iNext = 0;

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/advertisements.txt");

    KeyValues kv = new KeyValues("Advertisements");
    if (!kv.ImportFromFile(path))
    {
        LogError("[SimpleAds] cannot read %s", path);
        delete kv;
        return;
    }
    if (kv.GotoFirstSubKey())
    {
        char text[256];
        do
        {
            kv.GetString("text", text, sizeof(text));
            TrimString(text);
            if (text[0])
                g_Ads.PushString(text);
        } while (kv.GotoNextKey());
    }
    delete kv;
    LogMessage("[SimpleAds] loaded %d message(s)", g_Ads.Length);
}

void RestartTimer()
{
    if (g_hTimer != null)
    {
        KillTimer(g_hTimer);
        g_hTimer = null;
    }
    if (g_cvEnabled.BoolValue && g_Ads.Length > 0)
        g_hTimer = CreateTimer(g_cvInterval.FloatValue, Timer_ShowAd,
                              _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ShowAd(Handle timer)
{
    if (!g_cvEnabled.BoolValue || g_Ads.Length == 0)
        return Plugin_Continue;

    char text[256];
    g_Ads.GetString(g_iNext % g_Ads.Length, text, sizeof(text));
    g_iNext++;

    ReplaceString(text, sizeof(text), "{DEFAULT}", "\x01");
    ReplaceString(text, sizeof(text), "{GREEN}", "\x04");
    ReplaceString(text, sizeof(text), "{LIGHTGREEN}", "\x03");
    ReplaceString(text, sizeof(text), "{RED}", "\x02");
    ReplaceString(text, sizeof(text), "{OLIVE}", "\x05");
    ReplaceString(text, sizeof(text), "{BLUE}", "\x03");
    ReplaceString(text, sizeof(text), "{ORANGE}", "\x04");

    PrintToChatAll("%s", text);
    return Plugin_Continue;
}
