import os, re, sys

BASE = "/opt/counter/server/cstrike"

MODELS = [
    ("models/player/bzplayer/ct_gign.mdl", ["materials/models/player/mwghost"]),
    ("models/player/tf141/ct_gsg9.mdl", ["materials/models/humangrunt"]),
    ("models/player/tf141/ct_sas.mdl", ["materials/models/humangrunt"]),
    ("models/player/tf141/ct_urban.mdl", ["materials/models/humangrunt"]),
    ("models/player/gorka/t_phoenix.mdl", ["materials/models/player/vad36airborne"]),
    ("models/player/merc/t_leet.mdl", ["materials/models/player/vad36mercenary"]),
    ("models/player/jug1/t_guerilla.mdl", ["materials/models/player/vad36eswat"]),
    ("models/player/spetz/t_arctic.mdl", ["materials/models/player"]),
]

def strings_of(path):
    data = open(path, "rb").read()
    out = set()
    cur = b""
    for b in data:
        if 32 <= b < 127:
            cur += bytes([b])
        else:
            if len(cur) >= 3:
                out.add(cur.decode("ascii", "ignore").lower())
            cur = b""
    return out

def walk_files(root):
    res = []
    for dp, dn, fn in os.walk(root):
        for f in fn:
            res.append(os.path.join(dp, f))
    return res

total = []
for mdl, matroots in MODELS:
    mdl_abs = os.path.join(BASE, mdl)
    strs = strings_of(mdl_abs)
    # model sibling files
    d = os.path.dirname(mdl_abs)
    base = os.path.splitext(os.path.basename(mdl))[0]
    sibs = [os.path.join(d, f) for f in os.listdir(d)
            if f.startswith(base + ".") and not f.endswith(".bz2")]
    rel_sibs = [os.path.relpath(s, BASE) for s in sibs]
    # material candidates: files under matroots whose basename appears in mdl strings
    cand = []
    for mr in matroots:
        for f in walk_files(os.path.join(BASE, mr)):
            stem = os.path.splitext(os.path.basename(f))[0].lower()
            rel = os.path.relpath(f, BASE)
            if mr.endswith("player") and "spetsnaz" not in rel:
                continue
            if stem in strs:
                cand.append(rel)
    # parse chosen VMTs for texture refs, add referenced vtfs
    extra = []
    for rel in list(cand):
        if rel.endswith(".vmt"):
            try:
                txt = open(os.path.join(BASE, rel), errors="ignore").read().lower()
            except Exception:
                continue
            for m in re.findall(r'"\$[a-z0-9_]+"\s+"([^"]+)"', txt):
                p = m.replace("\\", "/")
                for ext in (".vtf", ".vmt"):
                    full = os.path.join(BASE, "materials", p + ext)
                    if os.path.exists(full):
                        r = os.path.relpath(full, BASE)
                        if r not in cand and r not in extra:
                            extra.append(r)
    files = sorted(set(rel_sibs + cand + extra))
    print(f"== {mdl}: {len(files)} files")
    for f in files:
        print("   ", f)
    total += files

total = sorted(set(total))
print(f"TOTAL unique: {len(total)}")
with open("/tmp/model_files.txt", "w") as fh:
    fh.write("\n".join(total))
