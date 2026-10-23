#include <sourcemod>
#include <sdktools>

// Wh1Tes G7 Props — the G7 pack's rechargers and cssflags, live on the
// server (Ali's order: "install EVERYTHING from G7"). Spawns at each
// team's spawn: a health charger, a suit (armor) charger and the team
// flag. Hold USE next to a charger to charge HP/armor; charger pools
// are limited and regenerate. Pack sounds: medshot4/medshotno1 (HP),
// suitchargeok1/suitchargeno1 (armor).

public Plugin myinfo =
{
    name = "Wh1Tes G7 Props",
    author = "Wh1Tes",
    description = "G7 recharger stations + team flags at spawns",
    version = "1.0.0",
    url = ""
};

#define MAX_CHARGERS 8
int g_iChargerEnt[MAX_CHARGERS];   // entity refs
int g_iChargerKind[MAX_CHARGERS];  // 0 = health, 1 = suit
int g_iPool[MAX_CHARGERS];
int g_iChargerCount;
int g_iFlagEnt[2];
bool g_bPrecached;
bool g_bSpawned;
float g_fDenyAt[MAXPLAYERS + 1];

public void OnPluginStart()
{
    DoPrecache();
    CreateTimer(5.0, Timer_TrySpawn); // late-load path
    CreateTimer(0.2, Timer_Tick, _, TIMER_REPEAT);
    RegServerCmd("sm_g7props", Cmd_Props, "List the G7 chargers (diagnostics)");
}

void DoPrecache()
{
    if (g_bPrecached)
        return;
    PrecacheModel("models/recharger/health_charger001.mdl", true);
    PrecacheModel("models/recharger/suit_charger001.mdl", true);
    PrecacheModel("models/cssflags/flag.mdl", true);
    PrecacheSound("rechargers/medshot4.wav", true);
    PrecacheSound("rechargers/medshotno1.wav", true);
    PrecacheSound("rechargers/suitchargeok1.wav", true);
    PrecacheSound("rechargers/suitchargeno1.wav", true);
    g_bPrecached = true;
}

public Action Cmd_Props(int args)
{
    PrintToServer("[g7props] spawned=%d chargers=%d", g_bSpawned, g_iChargerCount);
    for (int c = 0; c < g_iChargerCount; c++)
    {
        int ent = EntRefToEntIndex(g_iChargerEnt[c]);
        if (ent == -1)
        {
            PrintToServer("[g7props] charger %d: GONE", c);
            continue;
        }
        float pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        PrintToServer("[g7props] charger %d kind=%d pool=%d at %.0f %.0f %.0f", c, g_iChargerKind[c], g_iPool[c], pos[0], pos[1], pos[2]);
    }
    PrintToServer("[g7props] flags: ct=%d t=%d", EntRefToEntIndex(g_iFlagEnt[0]), EntRefToEntIndex(g_iFlagEnt[1]));
    return Plugin_Handled;
}

public void OnMapStart()
{
    DoPrecache();
    char path[128];
    char files[][] = {
        "models/recharger/health_charger001.mdl", "models/recharger/health_charger001.vvd",
        "models/recharger/health_charger001.phy", "models/recharger/health_charger001.dx90.vtx",
        "models/recharger/suit_charger001.mdl", "models/recharger/suit_charger001.vvd",
        "models/recharger/suit_charger001.phy", "models/recharger/suit_charger001.dx90.vtx",
        "models/cssflags/flag.mdl", "models/cssflags/flag.vvd", "models/cssflags/flag.dx90.vtx",
        "materials/models/recharger/health_charger001.vmt", "materials/models/recharger/health_charger001.vtf",
        "materials/models/recharger/health_charger_glass.vmt", "materials/models/recharger/health_charger_glass.vtf",
        "materials/models/recharger/suit_charger001_sheet.vmt", "materials/models/recharger/suit_charger001_sheet.vtf",
        "materials/models/recharger/back.vmt", "materials/models/recharger/back.vtf",
        "materials/models/cssflags/flag_ct.vmt", "materials/models/cssflags/flag_ct.vtf",
        "materials/models/cssflags/flag_t.vmt", "materials/models/cssflags/flag_t.vtf",
        "materials/models/cssflags/flag_neutral.vmt", "materials/models/cssflags/flag_neutral.vtf",
        "sound/rechargers/medshot4.wav", "sound/rechargers/medshotno1.wav",
        "sound/rechargers/suitchargeok1.wav", "sound/rechargers/suitchargeno1.wav"
    };
    for (int i = 0; i < sizeof(files); i++)
    {
        strcopy(path, sizeof(path), files[i]);
        AddFileToDownloadsTable(path);
    }
    g_bSpawned = false;
}

public Action Timer_TrySpawn(Handle timer)
{
    SpawnProps();
    return Plugin_Stop;
}

void SpawnProps()
{
    if (g_bSpawned)
        return;
    g_iChargerCount = 0;
    int ctSpawn = FindEntityByClassname(-1, "info_player_counterterrorist");
    int tSpawn = FindEntityByClassname(-1, "info_player_terrorist");
    if (ctSpawn == -1 && tSpawn == -1)
        return; // map not ready yet
    if (ctSpawn != -1)
        SpawnTeamSet(ctSpawn, 0);
    if (tSpawn != -1)
        SpawnTeamSet(tSpawn, 1);
    g_bSpawned = true;
    PrintToServer("[g7props] chargers + flags spawned (%d chargers)", g_iChargerCount);
}

void SpawnTeamSet(int spawnEnt, int skin)
{
    float origin[3], ang[3], right[3], pos[3];
    GetEntPropVector(spawnEnt, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(spawnEnt, Prop_Send, "m_angRotation", ang);
    GetAngleVectors(ang, NULL_VECTOR, right, NULL_VECTOR);

    // health charger: +45 right of spawn
    pos[0] = origin[0] + right[0] * 45.0; pos[1] = origin[1] + right[1] * 45.0; pos[2] = origin[2] + 4.0;
    AddCharger("models/recharger/health_charger001.mdl", pos, ang, 0);
    // suit charger: -45 right of spawn
    pos[0] = origin[0] - right[0] * 45.0; pos[1] = origin[1] - right[1] * 45.0; pos[2] = origin[2] + 4.0;
    AddCharger("models/recharger/suit_charger001.mdl", pos, ang, 1);
    // team flag: +90 forward of spawn
    float fwd[3];
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
    pos[0] = origin[0] + fwd[0] * 90.0; pos[1] = origin[1] + fwd[1] * 90.0; pos[2] = origin[2];
    int flag = CreateEntityByName("prop_dynamic");
    if (flag != -1)
    {
        SetEntityModel(flag, "models/cssflags/flag.mdl");
        SetEntProp(flag, Prop_Send, "m_nSkin", skin);
        DispatchSpawn(flag);
        TeleportEntity(flag, pos, ang, NULL_VECTOR);
        SetEntProp(flag, Prop_Send, "m_CollisionGroup", 1);
        g_iFlagEnt[skin] = EntIndexToEntRef(flag);
    }
}

void AddCharger(const char[] model, float pos[3], float ang[3], int kind)
{
    if (g_iChargerCount >= MAX_CHARGERS)
        return;
    // prop_dynamic_override + SOLID_NONE: the HL-style charger models
    // carry physics data; a plain prop_dynamic gets vphysics-killed
    // on this build (flags with the same pattern survived, chargers
    // did not).
    int ent = CreateEntityByName("prop_dynamic_override");
    if (ent == -1)
        return;
    SetEntityModel(ent, model);
    DispatchSpawn(ent);
    ActivateEntity(ent);
    TeleportEntity(ent, pos, ang, NULL_VECTOR);
    SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
    SetEntProp(ent, Prop_Data, "m_nSolidType", 0);
    g_iChargerEnt[g_iChargerCount] = EntIndexToEntRef(ent);
    g_iChargerKind[g_iChargerCount] = kind;
    g_iPool[g_iChargerCount] = 75;
    g_iChargerCount++;
}

public Action Timer_Tick(Handle timer)
{
    if (!g_bSpawned)
    {
        SpawnProps();
        return Plugin_Continue;
    }
    // passive pool regen
    for (int c = 0; c < g_iChargerCount; c++)
        if (g_iPool[c] < 75)
            g_iPool[c]++;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
            continue;
        if (!(GetClientButtons(i) & IN_USE))
            continue;
        float ppos[3];
        GetClientAbsOrigin(i, ppos);
        for (int c = 0; c < g_iChargerCount; c++)
        {
            int ent = EntRefToEntIndex(g_iChargerEnt[c]);
            if (ent == -1)
                continue;
            float epos[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", epos);
            if (GetVectorDistance(ppos, epos) > 110.0)
                continue;
            // in range of charger c
            if (g_iChargerKind[c] == 0)
            {
                int hp = GetClientHealth(i);
                if (hp >= 100)
                    continue;
                if (g_iPool[c] <= 0)
                {
                    Deny(i, "rechargers/medshotno1.wav");
                    continue;
                }
                SetEntityHealth(i, hp + 2 > 100 ? 100 : hp + 2);
                g_iPool[c] -= 2;
                EmitSoundToAll("rechargers/medshot4.wav", ent);
            }
            else
            {
                int ap = GetClientArmor(i);
                if (ap >= 100)
                    continue;
                if (g_iPool[c] <= 0)
                {
                    Deny(i, "rechargers/suitchargeno1.wav");
                    continue;
                }
                SetEntProp(i, Prop_Send, "m_ArmorValue", ap + 2 > 100 ? 100 : ap + 2);
                g_iPool[c] -= 2;
                EmitSoundToAll("rechargers/suitchargeok1.wav", ent);
            }
            break; // one charger per tick per player
        }
    }
    return Plugin_Continue;
}

void Deny(int client, const char[] sound)
{
    float now = GetGameTime();
    if (now - g_fDenyAt[client] < 1.0)
        return;
    g_fDenyAt[client] = now;
    EmitSoundToClient(client, sound);
}
