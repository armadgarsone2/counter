import os, re, json

BASE = "/opt/counter/server/cstrike"
files = set(l.strip() for l in open("/tmp/weapon_files.txt") if l.strip())

# recursively follow VMT texture references
def refs_of(vmt_rel):
    p = os.path.join(BASE, vmt_rel)
    try:
        txt = open(p, errors="ignore").read().lower()
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
added = 0
while queue:
    cur = queue.pop()
    for r in refs_of(cur):
        if r not in files:
            files.add(r)
            added += 1
            if r.endswith(".vmt") and r not in seen:
                seen.add(r)
                queue.append(r)

files = sorted(files)
open("/tmp/weapon_files2.txt", "w").write("\n".join(files))
print("weapon downloads now:", len(files), "(added", added, ")")

# regenerate weapons plugin source with new list + fire/reload hooks
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
W.append('\tdescription = "MW3 weapon models via new paths",')
W.append('\tversion     = "1.1.0",')
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
for f in files:
    W.append('\tAddFileToDownloadsTable("%s");' % f)
W.append('}')
W.append('')
W.append('public void OnPluginStart()')
W.append('{')
W.append('\tHookEvent("item_pickup", Event_Pickup);')
W.append('\tHookEvent("weapon_fire", Event_Fire);')
W.append('\tHookEvent("weapon_reload", Event_Fire);')
W.append('\tHookEvent("weapon_zoom", Event_Fire);')
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
W.append('public void Event_Fire(Event event, const char[] name, bool dontBroadcast)')
W.append('{')
W.append('\tint client = GetClientOfUserId(event.GetInt("userid"));')
W.append('\tif (client > 0)')
W.append('\t\tCreateTimer(0.08, Timer_ViewModel, GetClientSerial(client));')
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
print("weapons plugin v1.1 written")
