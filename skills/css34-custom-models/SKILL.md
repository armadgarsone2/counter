# CS:S v34 — Custom Player Models, Weapons & Server Polish

Hard-won playbook for Ali's Counter-Strike: Source v34 server (Stockholm,
`/opt/counter`, css34.service). Everything here was verified live on
2026-10-20 against the SourceMod 1.7.3-css34 fork. Read the base skill
`css34-server` first for connection/RCON basics.

## The golden rule of compiling on this server

The 1.7.3-css34 runtime loads and runs ONLY plugins compiled with
**SourceMod 1.9** (`sourcemod-1.9.0-git6282`, kept at `/tmp/sm19` on the
server; re-download from sm.alliedmods.net smdrop/1.9 if /tmp was wiped).

- SM 1.12 .smx → load error 27 "Plugin format is too new" (`<Bad Load>`).
- SM 1.10 .smx → loads, but `PrecacheModel` in OnMapStart **SEGVs srcds**.
- Compile: `/tmp/sm19/addons/sourcemod/scripting/spcomp <src> -i/tmp/sm19/addons/sourcemod/scripting/include -o<plugins>/<name>.smx`
- A plugin "works" only when `sm plugins list` shows name+version with no
  `<Bad Load>`/`<Failed>` — never trust anything else.
- Natives differ between the 1.9 includes and the 1.7.3 runtime:
  `RemoveEntity` does NOT exist at runtime — use `AcceptEntityInput(ent, "Kill")`.
- SM error logs live in `addons/sourcemod/logs/` — the dir may not exist;
  create it or plugin errors are invisible.

## Player models (SOLVED — Wh1Tes Models v5.1)

- NEVER overwrite the stock-path player model sets (`models/player/ct_*.mdl`
  etc.) with pack files (model format 48): srcds SEGV-crash-loops at startup.
  The same files are safe when applied by a plugin from SUBFOLDER paths.
  Originals are git-tracked — restore with `git checkout -- <path>`.
- Plugin pattern: precache in `OnMapStart`, apply in `player_spawn` via a
  0.3 s timer + `GetClientSerial`; match the client's current stock model
  basename (`ct_gign.mdl` …) to pick the replacement.
- Downloads table: register the models' sibling files + materials. Registering
  too much CRASHES real clients at connect: ~2,600 entries = crash on
  connect; ~1,200 worked; current ~750 player + extras is safe. Never
  register `.bz2` files themselves or recursive junk.
- Materials: register the models' COMPLETE cdmaterials leaf directories —
  string-matching the .mdl misses textures and players render **purple**
  (missing texture). Follow VMT `$basetexture`/`$bumpmap`/… refs recursively.
- When a model's own materials dir is a renamed copy (e.g. ct_gign → mwghost),
  hex-patch the .mdl's cdmaterials string with a SAME-LENGTH replacement.
- If some pack variants share textures (e.g. TF141 models reference a texture
  in the arctic variant's dir), keep those dirs in the game tree — moving
  "spares" out breaks the registered list (404s in the FastDL log).

## FastDL facts

- `/var/www/fastdl/cstrike/{models,materials,sound,maps}` are SYMLINKS into
  the game tree — `du`/`find` numbers lie. Access log:
  `/var/log/nginx/fastdl.access.log` (per-IP sessions; Ali's IPs rotate).
- Build `.bz2` next to every registered file; the client asks for the `.bz2`
  first and falls back to the raw file on 404 (a `.bz2` 404 alone is benign).
- A client's 404 list in this log = ground truth for missing downloads.
- sv_pure 1 whitelist backup `.bak` is MALFORMED (paths with no rule type) —
  never restore it; `.bak2` is the good one (6 trusted_source rules).

## Weapon skins (ABANDONED by Ali's order 2026-10-20 — lessons kept)

Do not rebuild this unless Ali asks again. What was learned:

- Stock-path pack files NEVER reach an existing client: the client already
  has files at those paths and won't re-download them; sv_pure
  `trusted_source` doesn't force it either.
- Relocating models to a NEW path (e.g. `models/weapons/mw3/`) makes them
  downloadable. In CS:S the weapon ENTITY's `m_ModelName` is the **v_** model;
  the view/world models are driven by the networked props
  `m_iViewModelIndex` / `m_iWorldModelIndex` on the weapon entity (set them
  from `PrecacheModel` return values).
- **Case-sensitivity trap:** pack .mdl cdmaterials often use UPPERCASE dirs
  (`models\weapons\v_models\MW3_AK47\`) while disk dirs are lowercase. A
  Linux-side analyzer with `os.path.exists` silently skips them → 264 texture
  files missing → world guns render **purple**. Resolve all .mdl string
  paths CASE-INSENSITIVELY (build a lowercase→real path map of the tree).
  Also: w_ models commonly point into the **v_models** material dirs.
- This client build (clientmod) re-derives the first-person viewmodel: the
  owner's view stayed stock even with correct networked indexes (others saw
  the custom world model fine). Re-forcing `SetEntityModel` on the viewmodel
  entity every 0.3 s causes visible stock↔skin FLICKER — worse. Ali killed
  the feature; final state: plugin removed, `models/weapons` +
  `materials/models/weapons` restored to stock via git checkout + clean.

## This build's config quirks

- `exec` of cfg files GARBLES lines (overlapping fragments → "Unknown
  command" spam; values silently never apply). `gamemodes/*.cfg` therefore
  don't reliably apply at map load. Reliable channels, in order:
  1. Cvars INLINE in `server.cfg` (parsed cleanly at startup).
  2. Plugin code — set game cvars with `FindConVar(...).SetInt()` in
     `OnMapStart` + `round_start` (bulletproof; this is how classic rules
     are enforced: `mp_freezetime 0`, `mp_startmoney 16000`).
  3. Direct RCON sets (immediate, but lost on map change).
- Plugin cvars created in OnPluginStart may not exist yet when server.cfg
  runs — don't gate features on cfg-set plugin cvars; use a CreateConVar
  DEFAULT or AutoExecConfig + `cfg/sourcemod/<plugin>.cfg`.

## Classic-mode rules (live)

- Plugin `round_money` (Wh1Tes Round Money): cvar `wh1tes_maxmoney`
  (default 1) → at `player_spawn` + 0.2 s, `SetEntProp(client, Prop_Send,
  "m_iAccount", 16000)`. It also enforces freezetime/startmoney per above.
- `bot_quota=2` + `bot_join_after_player=1` in the gamemode config: bots only
  join after a human — for bot-only tests set it to 0 temporarily, restore 1.
  `bot_add_ct` / `bot_add_t` via RCON add one immediately.
- Stock T/CT model sets print `Error Vertex File` warnings — pre-existing
  repo .vvd mismatches; harmless noise, not a failure.

## Dense smoke (live — Wh1Tes Dense Smoke)

Client-side smoke density can't be changed from the server; instead hook
`smokegrenade_detonate` (event carries x/y/z) and spawn an `env_smokestack`
at the spot: SmokeMaterial `particle/particle_smokegrenade.vmt`, StartSize
70, EndSize 170, Rate 45, JetLength 55, Speed 10, BaseSpread 30 — TurnOn,
kill after 19 s (TurnOff + Kill input).

## Admin on this no-Steam build

- Clients show `STEAM_ID_PENDING`; auth is name+password in
  `admins_simple.ini` (`"Name" "99:z" "pass"`), `setinfo _password "pass"` in
  the game console once (PassInfoVar `_password` in core.cfg), then
  `sm_reloadadmins`. The pre-existing `"VALVE_0:0:0" "z"` entry stays.

## Debugging method that worked

- A 30-line diagnostic plugin (compile 1.9, `sm plugins load` LIVE — no
  restart) logging real prop values on `item_pickup` beats guessing:
  it proved the mw3 indexes (AK: view 167 / world 207 vs stock 64 / 65)
  were set while the client still showed stock.
- Diff the downloads list against the client's fetched set from
  `fastdl.access.log` (strip `.bz2` suffixes) to find never-delivered files.
- Verify with A2S/RCON after every change; report only what was observed.
