#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Wh1Tes RPG — the G7 pack's vrpg7 view model: replaces the AWP view
// model for the player holding it (Ali's order: "install EVERYTHING
// from G7"). World model untouched (the pack ships only the v_ model).

public Plugin myinfo =
{
    name = "Wh1Tes RPG",
    author = "Wh1Tes",
    description = "G7 vrpg7 view model on the AWP",
    version = "1.0.0",
    url = ""
};

#define RPG_MODEL "models/weapons/vrpg7.mdl"

public void OnPluginStart()
{
    PrecacheModel(RPG_MODEL, true); // late-load safe: also done in OnMapStart
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnMapStart()
{
    PrecacheModel(RPG_MODEL, true);
    char path[128];
    char files[][] = {
        "models/weapons/vrpg7.mdl", "models/weapons/vrpg7.vvd", "models/weapons/vrpg7.dx90.vtx",
        "materials/models/weapons/v_rpg/aim.vmt", "materials/models/weapons/v_rpg/aim.vtf",
        "materials/models/weapons/v_rpg/mesh4.vmt", "materials/models/weapons/v_rpg/mesh4.vtf",
        "materials/models/weapons/v_rpg/rpg_barrel.vtf", "materials/models/weapons/v_rpg/rpg_barrel_color.vmt",
        "materials/models/weapons/v_rpg/rpg_rocket.vtf", "materials/models/weapons/v_rpg/rpg_rocket_color.vmt",
        "materials/models/weapons/v_rpg/trijiflex.vmt", "materials/models/weapons/v_rpg/trijiflex.vtf"
    };
    for (int i = 0; i < sizeof(files); i++)
    {
        strcopy(path, sizeof(path), files[i]);
        AddFileToDownloadsTable(path);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch(int client, int weapon)
{
    if (!IsClientInGame(client) || IsFakeClient(client) || !IsValidEntity(weapon))
        return;
    char classname[24];
    GetEntityClassname(weapon, classname, sizeof(classname));
    if (!StrEqual(classname, "weapon_awp"))
        return;
    int vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
    if (vm != -1)
        SetEntityModel(vm, RPG_MODEL);
}
