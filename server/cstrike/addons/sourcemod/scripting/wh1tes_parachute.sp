#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes Parachute",
    author = "Wh1Tes",
    description = "Hold USE while falling to open the carbon parachute (G7 pack)",
    version = "1.0.0"
};

#define PARA_MODEL "models/parachute/parachute_carbon.mdl"
#define FALL_CAP   -55.0
#define OPEN_SPEED -120.0

int g_iParaEnt[MAXPLAYERS + 1];

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
        g_iParaEnt[i] = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
    PrecacheModel(PARA_MODEL, true);
    AddFileToDownloadsTable("models/parachute/parachute_carbon.mdl");
    AddFileToDownloadsTable("models/parachute/parachute_carbon.vvd");
    AddFileToDownloadsTable("models/parachute/parachute_carbon.dx90.vtx");
    AddFileToDownloadsTable("materials/models/parachute/parachute_carbon.vmt");
    AddFileToDownloadsTable("materials/models/parachute/parachute_carbon.vtf");
    AddFileToDownloadsTable("materials/models/parachute/pack_carbon.vmt");
    AddFileToDownloadsTable("materials/models/parachute/pack_carbon.vtf");
}

public void OnClientDisconnect(int client)
{
    ClosePara(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3],
                             float angles[3], int &weapon, int &subtype, int &cmdnum,
                             int &tickcount, int &seed, int mouse[2])
{
    if (client < 1 || client > MaxClients || IsFakeClient(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    int flags = GetEntityFlags(client);
    if (flags & FL_ONGROUND)
    {
        ClosePara(client);
        return Plugin_Continue;
    }

    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

    if ((buttons & IN_USE) && velocity[2] < OPEN_SPEED)
    {
        OpenPara(client);
        if (velocity[2] < FALL_CAP)
        {
            velocity[2] = FALL_CAP;
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
        }
        MovePara(client, angles);
    }
    else
    {
        ClosePara(client);
    }
    return Plugin_Continue;
}

void OpenPara(int client)
{
    if (g_iParaEnt[client] != INVALID_ENT_REFERENCE)
    {
        int ent = EntRefToEntIndex(g_iParaEnt[client]);
        if (ent > MaxClients && IsValidEntity(ent))
            return;
        g_iParaEnt[client] = INVALID_ENT_REFERENCE;
    }

    int ent = CreateEntityByName("prop_dynamic_override");
    if (ent == -1)
        return;
    DispatchKeyValue(ent, "model", PARA_MODEL);
    DispatchKeyValue(ent, "solid", "0");
    DispatchSpawn(ent);
    SetEntityMoveType(ent, MOVETYPE_NOCLIP);
    SetEntProp(ent, Prop_Send, "m_nSolidType", 0);
    g_iParaEnt[client] = EntIndexToEntRef(ent);
}

void MovePara(int client, float angles[3])
{
    if (g_iParaEnt[client] == INVALID_ENT_REFERENCE)
        return;
    int ent = EntRefToEntIndex(g_iParaEnt[client]);
    if (ent <= MaxClients || !IsValidEntity(ent))
    {
        g_iParaEnt[client] = INVALID_ENT_REFERENCE;
        return;
    }
    float pos[3];
    GetClientAbsOrigin(client, pos);
    pos[2] += 58.0;
    float ang[3];
    ang[1] = angles[1];
    TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

void ClosePara(int client)
{
    if (g_iParaEnt[client] == INVALID_ENT_REFERENCE)
        return;
    int ent = EntRefToEntIndex(g_iParaEnt[client]);
    g_iParaEnt[client] = INVALID_ENT_REFERENCE;
    if (ent > MaxClients && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
}
