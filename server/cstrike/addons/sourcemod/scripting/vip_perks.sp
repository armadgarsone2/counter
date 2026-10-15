/*
 * VIP Cheat Perks for Counter-Strike: Source (v34)
 * Gives paying VIP players cheat-like perks on YOUR server.
 *
 * Install:
 *  1. Install MetaMod:Source + SourceMod (use a v34-compatible build, e.g. SourceMod 1.5.x)
 *  2. Compile this file with spcomp -> vip_perks.smx
 *  3. Put vip_perks.smx in: cstrike/addons/sourcemod/plugins/
 *  4. Give buyers the "o" flag in: cstrike/addons/sourcemod/configs/admins.cfg
 *     Example: "STEAM_0:1:123456"  "o"   // or use IP: "!127.0.0.1" "o"
 *  5. Restart server (or: sm plugins load vip_perks)
 *
 * VIP commands (chat or console):
 *   !vn  or  sm_vip_noclip  - toggle noclip
 *   !vg  or  sm_vip_god     - toggle godmode
 *   !vw  or  sm_vip_guns    - give all weapons
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define VIP_FLAG ADMFLAG_CUSTOM1   // "o" flag in admins.cfg

bool g_bGod[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name        = "VIP Cheat Perks",
    author      = "Server Owner",
    description = "Paid VIP perks: noclip, godmode, all weapons",
    version     = "1.0.0",
    url         = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_vip_noclip", Cmd_VipNoclip, VIP_FLAG, "VIP: toggle noclip");
    RegAdminCmd("sm_vip_god",    Cmd_VipGod,    VIP_FLAG, "VIP: toggle godmode");
    RegAdminCmd("sm_vip_guns",   Cmd_VipGuns,   VIP_FLAG, "VIP: give all weapons");

    // short chat triggers
    RegAdminCmd("sm_vn", Cmd_VipNoclip, VIP_FLAG, "VIP: toggle noclip (short)");
    RegAdminCmd("sm_vg", Cmd_VipGod,    VIP_FLAG, "VIP: toggle godmode (short)");
    RegAdminCmd("sm_vw", Cmd_VipGuns,   VIP_FLAG, "VIP: give all weapons (short)");

    // keep godmode persistent across respawns
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnClientDisconnect(int client)
{
    g_bGod[client] = false;
}

// ---------------- noclip ----------------
public Action Cmd_VipNoclip(int client, int args)
{
    if (client == 0 || !IsClientInGame(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[VIP] You must be alive to use noclip.");
        return Plugin_Handled;
    }

    if (GetEntityMoveType(client) == MOVETYPE_NOCLIP)
    {
        SetEntityMoveType(client, MOVETYPE_WALK);
        PrintToChat(client, "[VIP] Noclip \x04OFF");
    }
    else
    {
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
        PrintToChat(client, "[VIP] Noclip \x04ON");
    }
    return Plugin_Handled;
}

// ---------------- godmode ----------------
public Action Cmd_VipGod(int client, int args)
{
    if (client == 0 || !IsClientInGame(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[VIP] You must be alive to use godmode.");
        return Plugin_Handled;
    }

    g_bGod[client] = !g_bGod[client];
    // m_takedamage: 2 = yes, 0 = no
    SetEntProp(client, Prop_Data, "m_takedamage", g_bGod[client] ? 0 : 2);
    PrintToChat(client, "[VIP] Godmode %s", g_bGod[client] ? "\x04ON" : "\x04OFF");
    return Plugin_Handled;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && g_bGod[client] && IsPlayerAlive(client))
    {
        // re-apply godmode after respawn
        SetEntProp(client, Prop_Data, "m_takedamage", 0);
    }
}

// ---------------- all weapons ----------------
public Action Cmd_VipGuns(int client, int args)
{
    if (client == 0 || !IsClientInGame(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[VIP] You must be alive.");
        return Plugin_Handled;
    }

    char weapons[][] = {
        "weapon_knife", "weapon_deagle", "weapon_usp", "weapon_glock",
        "weapon_ak47", "weapon_m4a1", "weapon_awp", "weapon_deagle",
        "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade",
        "weapon_knife", "item_kevlar", "item_assaultsuit", "item_nvgs"
    };

    for (int i = 0; i < sizeof(weapons); i++)
        GivePlayerItem(client, weapons[i]);

    PrintToChat(client, "[VIP] Weapons received.");
    return Plugin_Handled;
}
