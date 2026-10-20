import os, re, json

BASE = "/opt/counter/server/cstrike"
WDIR = os.path.join(BASE, "models/weapons")

def strings_of(path):
    data = open(path, "rb").read()
    out = []
    cur = b""
    for b in data:
        if 32 <= b < 127:
            cur += bytes([b])
        else:
            if len(cur) >= 3:
                out.append(cur.decode("ascii", "ignore"))
            cur = b""
    return out

models = sorted(f for f in os.listdir(WDIR) if f.endswith(".mdl"))
report = {}
all_cd = set()
for m in models:
    strs = strings_of(os.path.join(WDIR, m))
    cds = sorted(set(s.replace("\\", "/").lower() for s in strs
                     if s.lower().startswith("models/weapons") or s.lower().startswith("models\\weapons")))
    cds = [c if c.endswith("/") else c + "/" for c in cds]
    all_cd.update(cds)
    # textures: files under each cdmat dir whose stem appears in mdl strings
    low_strs = set(s.lower() for s in strs)
    tex = []
    for cd in cds:
        d = os.path.join(BASE, "materials", cd)
        if not os.path.isdir(d):
            continue
        for f in os.listdir(d):
            stem = os.path.splitext(f)[0].lower()
            if stem in low_strs:
                tex.append("materials/" + cd + f)
    report[m] = {"cdmaterials": cds, "textures": sorted(set(tex))}

stock = 0
newp = 0
for m, r in report.items():
    for t in r["textures"]:
        if "/v_models/" in t or "/w_models/" in t:
            stock += 1
        else:
            newp += 1
print(f"models: {len(models)}")
print(f"texture files needed: stock-path={stock} new-path={newp}")
print("cdmaterials roots:")
for c in sorted(all_cd):
    print("  ", c)
json.dump(report, open("/tmp/weapons_report.json", "w"), indent=1)
# which models use stock-path textures at all?
need = [m for m, r in report.items() if any("/v_models/" in t or "/w_models/" in t for t in r["textures"])]
print("models needing relocation:", len(need))
print(" ", ", ".join(need))
