#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

/*
 * Wh1Tes Death Dissolve v1.0
 *
 * When a player dies, their corpse gets an energy glow and dissolves away
 * within ~1-2 seconds instead of lying on the ground (like a Death Dissolve /
 * env_entity_dissolver effect).
 *
 * cvars: wh1tes_dissolve_delay (seconds after death before the effect, default 0.5)
 *        wh1tes_dissolve_enabled (1 = on, 0 = off, default 1)
 */

ConVar g_cvDelay;
ConVar g_cvEnabled;

public Plugin myinfo = {
    name = "Wh1Tes Death Dissolve",
    author = "Wh1Tes",
    description = "Corpses glow and dissolve with an energy effect shortly after death",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    g_cvDelay = CreateConVar("wh1tes_dissolve_delay", "0.5",
        "Seconds after death before the corpse starts dissolving", _, true, 0.0, true, 5.0);
    g_cvEnabled = CreateConVar("wh1tes_dissolve_enabled", "1",
        "1 = dissolve corpses with energy effect, 0 = leave stock ragdolls", _, true, 0.0, true, 1.0);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnabled.BoolValue)
        return;
    float delay = g_cvDelay.FloatValue;
    CreateTimer(delay, Timer_DissolveRagdolls, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DissolveRagdolls(Handle timer)
{
    if (!g_cvEnabled.BoolValue)
        return Plugin_Stop;

    // Collect first: dissolving changes the entity list while iterating.
    int ragdolls[64];
    int count = 0;
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "cs_ragdoll")) != -1 && count < sizeof(ragdolls))
        ragdolls[count++] = ent;

    for (int i = 0; i < count; i++)
        DissolveEntity(ragdolls[i]);

    return Plugin_Stop;
}

void DissolveEntity(int target)
{
    if (!IsValidEntity(target))
        return;

    int dissolver = CreateEntityByName("env_entity_dissolver");
    if (dissolver == -1)
        return;

    char tname[32];
    Format(tname, sizeof(tname), "wh1tes_dissolve_%d", target);
    DispatchKeyValue(target, "targetname", tname);
    DispatchKeyValue(dissolver, "target", tname);
    DispatchKeyValue(dissolver, "dissolvetype", "0"); // 0 = energy (glow + dissolve)
    DispatchSpawn(dissolver);
    ActivateEntity(dissolver);
    AcceptEntityInput(dissolver, "Dissolve");
    AcceptEntityInput(dissolver, "Kill");
}
