import os, re, json

BASE = "/opt/counter/server/cstrike"

# case-insensitive map of every material file
lowmap = {}
matroot = os.path.join(BASE, "materials")
for dp, dn, fn in os.walk(matroot):
    for f in fn:
        rel = os.path.relpath(os.path.join(dp, f), BASE)
        if not rel.endswith(".bz2"):
            lowmap[rel.lower()] = rel

def resolve(rel_lower):
    return lowmap.get(rel_lower.replace("\\", "/").lower())

def mdl_strings(path):
    try:
        data = open(path, "rb").read()
    except Exception:
        return []
    return [s.decode("ascii", "ignore") for s in re.findall(rb"[ -~]{3,}", data)]

files = set(l.strip() for l in open("/tmp/weapon_files2.txt") if l.strip())
wmap = json.load(open("/tmp/weapon_models.json"))

added = 0
for stock_rel, info in wmap.items():
    for mdl in (stock_rel, "models/weapons/mw3/" + os.path.basename(stock_rel)):
        strs = mdl_strings(os.path.join(BASE, mdl))
        cds = []
        names = []
        for s in strs:
            sl = s.replace("/", "\\")
            if sl.lower().startswith("models\\") and sl.endswith("\\"):
                cds.append(sl.replace("\\", "/"))
            elif re.fullmatch(r"[A-Za-z0-9_\-\. ]+", s) and " " not in s and "." not in s:
                names.append(s)
        for cd in cds:
            for n in names:
                for ext in (".vmt", ".vtf"):
                    r = resolve("materials/" + cd + n + ext)
                    if r and r not in files:
                        files.add(r)
                        added += 1

# recursive VMT follow (case-insensitive)
def refs_of(vmt_rel):
    try:
        txt = open(os.path.join(BASE, vmt_rel), errors="ignore").read().lower()
    except Exception:
        return []
    out = []
    for m in re.findall(r'"\$[a-z0-9_]+"\s+"([^"]+)"', txt):
        pp = m.replace("\\", "/")
        for ext in (".vtf", ".vmt"):
            r = resolve("materials/" + pp + ext)
            if r:
                out.append(r)
    return out

queue = [f for f in files if f.endswith(".vmt")]
seen = set(queue)
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
open("/tmp/weapon_files3.txt", "w").write("\n".join(files))
print("weapon downloads v3:", len(files), "(added", added, "by case-insensitive pass)")

# regenerate plugin source v1.6 with the new list (same logic as 1.5)
src = open("/tmp/wh1tes_weapons.sp").read()
head = src.split('AddFileToDownloadsTable')[0]
tail_marker = 'public void OnPluginStart()'
tail = src[src.index(tail_marker) - len('public void OnPluginStart()') + 0:]
# simpler: rebuild by splicing the downloads block
import re as _re
start = src.index('\tAddFileToDownloadsTable')
end = src.index('}', src.index('\tAddFileToDownloadsTable', start))
# find the end of OnMapStart: first "\n}\n" after start
end = src.index('\n}\n', start) + 1
newblock = "\n".join('\tAddFileToDownloadsTable("%s");' % f for f in files) + "\n"
src2 = src[:start] + newblock + src[end:]
src2 = src2.replace('"1.5.0"', '"1.6.0"')
open("/tmp/wh1tes_weapons.sp", "w").write(src2)
print("plugin v1.6 source written")
