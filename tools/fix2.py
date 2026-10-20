import os, re, json

BASE = "/opt/counter/server/cstrike"

# ---------- PLAYER downloads: complete leaf dirs + recursive VMT follow ----------
LEAF_DIRS = [
    "materials/models/player/mwghost",
    "materials/models/humangrunt/mw2/tf141brazil",
    "materials/models/humangrunt/mw2/soap",
    "materials/models/humangrunt/mw2/ghost",
    "materials/models/humangrunt/mw2/tf141arctic",
    "materials/models/player/vad36airborne",
    "materials/models/player/vad36mercenary",
    "materials/models/player/vad36eswat",
    "materials/models/player/spetsnaz_assault",
    "materials/models/player/spetsnaz_assault_arctic",
    "materials/models/player/spetsnaz_assault_guerilla",
    "materials/models/player/spetsnaz_assault_leet",
    "materials/models/player/spetsnaz_head",
    "materials/models/player/spetsnaz_head_arctic",
    "materials/models/player/spetsnaz_head_guerilla",
]
files = set()
for d in LEAF_DIRS:
    ap = os.path.join(BASE, d)
    for dp, dn, fn in os.walk(ap):
        for f in fn:
            if not f.endswith(".bz2"):
                files.add(os.path.relpath(os.path.join(dp, f), BASE))

# model siblings + shared anims (from previous exact list)
prev = [l.strip() for l in open("/tmp/model_files.txt") if l.strip()]
for f in prev:
    if f.startswith("models/"):
        files.add(f)
for extra in [
    "models/player/cs_player_shared.mdl", "models/player/cs_player_shared.vvd",
    "models/player/cs_player_shared.phy", "models/player/cs_player_shared.sw.vtx",
    "models/player/ak_anims_ct.mdl", "models/player/ak_anims_ct.vvd",
    "models/player/ak_anims_t.mdl", "models/player/ak_anims_t.vvd",
]:
    if os.path.exists(os.path.join(BASE, extra)):
        files.add(extra)

# recursive VMT follow
def refs_of(vmt_rel):
    try:
        txt = open(os.path.join(BASE, vmt_rel), errors="ignore").read().lower()
    except Exception:
        return []
    out = []
    for m in re.findall(r'"\$[a-z0-9_]+"\s+"([^"]+)"', txt):
        pp = m.replace("\\", "/")
        for ext in (".vtf", ".vmt"):
            rel = "materials/" + pp + ext
            if os.path.exists(os.path.join(BASE, rel)):
                out.append(rel)
    return out

queue = [f for f in files if f.endswith(".vmt")]
seen = set(queue)
while queue:
    cur = queue.pop()
    for r in refs_of(cur):
        if r not in files:
            files.add(r)
            if r.endswith(".vmt") and r not in seen:
                seen.add(r)
                queue.append(r)

files = sorted(files)
open("/tmp/player_files2.txt", "w").write("\n".join(files))
print("player downloads:", len(files))

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
L.append('\tdescription = "Modern military player models per class (full mats)",')
L.append('\tversion     = "5.1.0",')
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
print("player plugin v5.1 written")

# ---------- WEAPONS v1.2: model-index based ----------
wfiles = [l.strip() for l in open("/tmp/weapon_files2.txt") if l.strip()]
wmodels = sorted(set("models/weapons/mw3/" + os.path.basename(k)
                     for k in json.load(open("/tmp/weapon_models.json")).keys()))
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
W.append('\tdescription = "MW3 weapon models via new paths (index-based)",')
W.append('\tversion     = "1.2.0",')
W.append('\turl         = ""')
W.append('};')
W.append('')
W.append('char g_NewModels[][] = {')
for m in wmodels:
    W.append('\t"%s",' % m)
W.append('};')
W.append('int g_Idx[sizeof(g_NewModels)];')
W.append('')
W.append('int FindModel(const char[] basename)')
W.append('{')
W.append('\tchar path[PLATFORM_MAX_PATH];')
W.append('\tFormat(path, sizeof(path), "models/weapons/mw3/%s", basename);')
W.append('\tfor (int i = 0; i < sizeof(g_NewModels); i++)')
W.append('\t\tif (StrEqual(g_NewModels[i], path))')
W.append('\t\t\treturn i;')
W.append('\treturn -1;')
W.append('}')
W.append('')
W.append('void FixWeapon(int weapon)')
W.append('{')
W.append('\tif (!IsValidEntity(weapon))')
W.append('\t\treturn;')
W.append('\tchar model[PLATFORM_MAX_PATH];')
W.append('\tGetEntPropString(weapon, Prop_Data, "m_ModelName", model, sizeof(model));')
W.append('\tchar base[64];')
W.append('\tint pos = FindCharInString(model, \'/\', true);')
W.append('\tif (pos == -1)')
W.append('\t\treturn;')
W.append('\tstrcopy(base, sizeof(base), model[pos + 1]);')
W.append('\tint wi = FindModel(base);')
W.append('\tif (wi == -1)')
W.append('\t\treturn;')
W.append('\tSetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", g_Idx[wi]);')
W.append('\tSetEntityModel(weapon, g_NewModels[wi]);')
W.append('\tif (base[0] == \'w\' && base[1] == \'_\')')
W.append('\t{')
W.append('\t\tchar vbase[64];')
W.append('\t\tFormat(vbase, sizeof(vbase), "v_%s", base[2]);')
W.append('\t\tint vi = FindModel(vbase);')
W.append('\t\tif (vi != -1)')
W.append('\t\t\tSetEntProp(weapon, Prop_Send, "m_iViewModelIndex", g_Idx[vi]);')
W.append('\t}')
W.append('}')
W.append('')
W.append('void FixClientWeapons(int client)')
W.append('{')
W.append('\tfor (int s = 0; s < 5; s++)')
W.append('\t{')
W.append('\t\tint w = GetPlayerWeaponSlot(client, s);')
W.append('\t\tif (w > 0)')
W.append('\t\t\tFixWeapon(w);')
W.append('\t}')
W.append('}')
W.append('')
W.append('public void OnMapStart()')
W.append('{')
W.append('\tfor (int i = 0; i < sizeof(g_NewModels); i++)')
W.append('\t\tg_Idx[i] = PrecacheModel(g_NewModels[i], true);')
for f in wfiles:
    W.append('\tAddFileToDownloadsTable("%s");' % f)
W.append('}')
W.append('')
W.append('public void OnPluginStart()')
W.append('{')
W.append('\tHookEvent("item_pickup", Event_Pickup);')
W.append('\tHookEvent("player_spawn", Event_SpawnW);')
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
W.append('\tif (StrContains(classname, "weapon_") == 0)')
W.append('\t\tCreateTimer(0.15, Timer_FixWeapon, EntIndexToEntRef(entity));')
W.append('}')
W.append('')
W.append('public Action Timer_FixWeapon(Handle timer, int ref)')
W.append('{')
W.append('\tint entity = EntRefToEntIndex(ref);')
W.append('\tif (entity != INVALID_ENT_REFERENCE)')
W.append('\t\tFixWeapon(entity);')
W.append('\treturn Plugin_Stop;')
W.append('}')
W.append('')
W.append('public void OnSwitch(int client, int weapon)')
W.append('{')
W.append('\tif (weapon > 0)')
W.append('\t\tFixWeapon(weapon);')
W.append('}')
W.append('')
W.append('public void Event_Pickup(Event event, const char[] name, bool dontBroadcast)')
W.append('{')
W.append('\tint client = GetClientOfUserId(event.GetInt("userid"));')
W.append('\tif (client > 0)')
W.append('\t\tCreateTimer(0.1, Timer_FixClient, GetClientSerial(client));')
W.append('}')
W.append('')
W.append('public void Event_SpawnW(Event event, const char[] name, bool dontBroadcast)')
W.append('{')
W.append('\tint client = GetClientOfUserId(event.GetInt("userid"));')
W.append('\tif (client > 0)')
W.append('\t\tCreateTimer(0.4, Timer_FixClient, GetClientSerial(client));')
W.append('}')
W.append('')
W.append('public Action Timer_FixClient(Handle timer, int serial)')
W.append('{')
W.append('\tint client = GetClientFromSerial(serial);')
W.append('\tif (client > 0 && IsClientInGame(client))')
W.append('\t\tFixClientWeapons(client);')
W.append('\treturn Plugin_Stop;')
W.append('}')
open("/tmp/wh1tes_weapons.sp", "w").write("\n".join(W) + "\n")
print("weapons plugin v1.2 written: downloads =", len(wfiles))
