import os, json

BASE = "/opt/counter/server/cstrike"

# ---------- slim player plugin (v5) ----------
files = [l.strip() for l in open("/tmp/model_files.txt") if l.strip()]
for extra in [
    "models/cs_player_shared.mdl", "models/cs_player_shared.vvd",
    "models/cs_player_shared.phy", "models/cs_player_shared.sw.vtx",
    "models/cs_player_shared.dx80.vtx", "models/cs_player_shared.dx90.vtx",
    "models/player/cs_player_shared.mdl", "models/player/cs_player_shared.vvd",
    "models/player/cs_player_shared.phy", "models/player/cs_player_shared.sw.vtx",
    "models/player/ak_anims_ct.mdl", "models/player/ak_anims_ct.vvd",
    "models/player/ak_anims_t.mdl", "models/player/ak_anims_t.vvd",
]:
    if os.path.exists(os.path.join(BASE, extra)) and extra not in files:
        files.append(extra)

MODELS = [
    "models/player/bzplayer/ct_gign.mdl",
    "models/player/tf141/ct_gsg9.mdl",
    "models/player/tf141/ct_sas.mdl",
    "models/player/tf141/ct_urban.mdl",
    "models/player/gorka/t_phoenix.mdl",
    "models/player/merc/t_leet.mdl",
    "models/player/jug1/t_guerilla.mdl",
    "models/player/spetz/t_arctic.mdl",
]
STOCK = ["ct_gign.mdl", "ct_gsg9.mdl", "ct_sas.mdl", "ct_urban.mdl",
         "t_phoenix.mdl", "t_leet.mdl", "t_guerilla.mdl", "t_arctic.mdl"]

L = []
L.append('#pragma semicolon 1')
L.append('#pragma newdecls required')
L.append('#include <sourcemod>')
L.append('#include <sdktools>')
L.append('')
L.append('public Plugin myinfo =')
L.append('{')
L.append('\tname        = "Wh1Tes Models",')
L.append('\tauthor      = "Server Owner",')
L.append('\tdescription = "Modern military player models per class (slim)",')
L.append('\tversion     = "5.0.0",')
L.append('\turl         = ""')
L.append('};')
L.append('')
L.append('char g_Models[8][64] = {')
for m in MODELS:
    L.append('\t"%s",' % m)
L.append('};')
L.append('char g_Stock[8][32] = {')
for s in STOCK:
    L.append('\t"%s",' % s)
L.append('};')
L.append('')
L.append('public void OnMapStart()')
L.append('{')
L.append('\tfor (int i = 0; i < 8; i++)')
L.append('\t\tPrecacheModel(g_Models[i], true);')
for f in files:
    L.append('\tAddFileToDownloadsTable("%s");' % f)
L.append('}')
L.append('')
L.append('public void OnPluginStart()')
L.append('{')
L.append('\tHookEvent("player_spawn", Event_Spawn);')
L.append('}')
L.append('')
L.append('public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)')
L.append('{')
L.append('\tint client = GetClientOfUserId(event.GetInt("userid"));')
L.append('\tif (client < 1 || !IsClientInGame(client))')
L.append('\t\treturn;')
L.append('\tCreateTimer(0.3, Timer_Apply, GetClientSerial(client));')
L.append('}')
L.append('')
L.append('public Action Timer_Apply(Handle timer, int serial)')
L.append('{')
L.append('\tint client = GetClientFromSerial(serial);')
L.append('\tif (client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))')
L.append('\t\treturn Plugin_Stop;')
L.append('\tchar model[128];')
L.append('\tGetClientModel(client, model, sizeof(model));')
L.append('\tfor (int i = 0; i < 8; i++)')
L.append('\t{')
L.append('\t\tif (StrContains(model, g_Stock[i]) != -1)')
L.append('\t\t{')
L.append('\t\t\tSetEntityModel(client, g_Models[i]);')
L.append('\t\t\tbreak;')
L.append('\t\t}')
L.append('\t}')
L.append('\treturn Plugin_Stop;')
L.append('}')
open("/tmp/wh1tes_models_v5.sp", "w").write("\n".join(L) + "\n")
print("player plugin: downloads =", len(files))

# ---------- weapons plugin ----------
wfiles = [l.strip() for l in open("/tmp/weapon_files.txt") if l.strip()]
wmodels = sorted(set("models/weapons/mw3/" + os.path.basename(k)
                     for k in json.load(open("/tmp/weapon_models.json")).keys()))
# basenames set for the generic swap
basenames = sorted(set(os.path.basename(m) for m in wmodels))

W = []
W.append('#pragma semicolon 1')
W.append('#pragma newdecls required')
W.append('#include <sourcemod>')
W.append('#include <sdktools>')
W.append('#include <sdkhooks>')
W.append('')
W.append('public Plugin myinfo =')
W.append('{')
W.append('\tname        = "Wh1Tes Weapons",')
W.append('\tauthor      = "Server Owner",')
W.append('\tdescription = "MW3 weapon models via new paths",')
W.append('\tversion     = "1.0.0",')
W.append('\turl         = ""')
W.append('};')
W.append('')
W.append('char g_NewModels[][] = {')
for m in wmodels:
    W.append('\t"%s",' % m)
W.append('};')
W.append('')
W.append('bool IsSwappable(const char[] model)')
W.append('{')
for b in basenames:
    W.append('\tif (StrContains(model, "/%s") != -1) return true;' % b)
W.append('\treturn false;')
W.append('}')
W.append('')
W.append('void SwapModel(int entity)')
W.append('{')
W.append('\tchar model[PLATFORM_MAX_PATH];')
W.append('\tGetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));')
W.append('\tif (!IsSwappable(model))')
W.append('\t\treturn;')
W.append('\tchar base[64];')
W.append('\tint pos = FindCharInString(model, \'/\', true);')
W.append('\tstrcopy(base, sizeof(base), model[pos + 1]);')
W.append('\tchar newpath[PLATFORM_MAX_PATH];')
W.append('\tFormat(newpath, sizeof(newpath), "models/weapons/mw3/%s", base);')
W.append('\tSetEntityModel(entity, newpath);')
W.append('}')
W.append('')
W.append('public void OnMapStart()')
W.append('{')
W.append('\tfor (int i = 0; i < sizeof(g_NewModels); i++)')
W.append('\t\tPrecacheModel(g_NewModels[i], true);')
for f in wfiles:
    W.append('\tAddFileToDownloadsTable("%s");' % f)
W.append('}')
W.append('')
W.append('public void OnPluginStart()')
W.append('{')
W.append('\tHookEvent("item_pickup", Event_Pickup);')
W.append('\tfor (int i = 1; i <= MaxClients; i++)')
W.append('\t\tif (IsClientInGame(i))')
W.append('\t\t\tSDKHook(i, SDKHook_WeaponSwitchPost, OnSwitch);')
W.append('}')
W.append('')
W.append('public void OnClientPutInServer(int client)')
W.append('{')
W.append('\tSDKHook(client, SDKHook_WeaponSwitchPost, OnSwitch);')
W.append('}')
W.append('')
W.append('public void OnEntityCreated(int entity, const char[] classname)')
W.append('{')
W.append('\tif (StrContains(classname, "weapon_") == 0 || StrEqual(classname, "weapon_knife"))')
W.append('\t\tCreateTimer(0.15, Timer_SwapWeapon, EntIndexToEntRef(entity));')
W.append('}')
W.append('')
W.append('public Action Timer_SwapWeapon(Handle timer, int ref)')
W.append('{')
W.append('\tint entity = EntRefToEntIndex(ref);')
W.append('\tif (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))')
W.append('\t\tSwapModel(entity);')
W.append('\treturn Plugin_Stop;')
W.append('}')
W.append('')
W.append('public void OnSwitch(int client, int weapon)')
W.append('{')
W.append('\tCreateTimer(0.05, Timer_ViewModel, GetClientSerial(client));')
W.append('}')
W.append('')
W.append('public void Event_Pickup(Event event, const char[] name, bool dontBroadcast)')
W.append('{')
W.append('\tint client = GetClientOfUserId(event.GetInt("userid"));')
W.append('\tif (client > 0)')
W.append('\t\tCreateTimer(0.1, Timer_ViewModel, GetClientSerial(client));')
W.append('}')
W.append('')
W.append('public Action Timer_ViewModel(Handle timer, int serial)')
W.append('{')
W.append('\tint client = GetClientFromSerial(serial);')
W.append('\tif (client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))')
W.append('\t\treturn Plugin_Stop;')
W.append('\tint vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");')
W.append('\tif (vm > 0 && IsValidEntity(vm))')
W.append('\t\tSwapModel(vm);')
W.append('\treturn Plugin_Stop;')
W.append('}')
open("/tmp/wh1tes_weapons.sp", "w").write("\n".join(W) + "\n")
print("weapons plugin: models =", len(wmodels), "downloads =", len(wfiles))
