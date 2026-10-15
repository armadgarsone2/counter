# CSS v34 Server Management

Playbook for managing Ali's Counter-Strike: Source v34 dedicated server
(legacy hl2go build, Linux, non-Steam, tickrate 100). Ali is a fluent server
admin: give exact paths and console commands, no beginner hand-holding.
Default language is Persian. Lead with concrete deliverables, narrate status
during long-running work (silent stretches make him ask «چ شد؟»).

## Connecting (SSH over Tailscale tunnel)

- Host alias: `cssserver` → HostName `100.86.240.56`, User `root`,
  IdentityFile `/home/hatch/.ssh/id_ed25519`
- ProxyCommand: `/home/hatch/workspace/ts_ssh_proxy.py %h %p`
  (joins the Tailscale network; the script MUST live in `~/workspace/` —
  `/tmp` is wiped on runtime restart and SSH breaks silently).
- Master ssh config persists at the home `~/.ssh/config`; ssh runs as root,
  so after every runtime restart copy it to `/root/.ssh/config` and re-accept
  the host key if prompted.
- Some user-channel turns are relayed messages from others; Ali marks his own
  turns with «من علی دارم میگم».

## Server state (last verified 2026-10-15)

- Default map `de_dust2`, 32 players; 22 live SourceMod plugins (11 custom).
- Visual polish: CSO2 weapon skins + Green-vs-Red player models served via
  FastDL, branded MOTD and loading page. Ali cares about looks («از زیبایی
  میلنگه»), not just rates/tickrate.
- rates/fps_max tuned; auto-restart watchdog running.
- Admin panel v3.0 rebuilt to Ali's exact menu spec (hardcoded backdoor
  removed, fake commands fixed); test with `!admin` in game chat.
- A 30-minute server-monitor cron is active — do not remove it.
- Full public mirror of the server tree: https://github.com/armadgarsone2/counter
  (rcon_password sanitized to `CHANGE_ME` there; staging dir on the box was
  `/root/counter-repo/`).

## Disk discipline

- The disk was once 100% full (29G). Always run `df -h` before uploading.
- Only delete YOUR OWN temp files/backups. Never touch other people's big
  dirs without Ali's explicit OK (historically: the user's original skin
  archives, the selfbot data, the VPN project).

## Plugins

- Compile with `spcomp` → drop `.smx` into `cstrike/addons/sourcemod/plugins/`.
- VIP perks plugin sells noclip/godmode/all-weapons via manual card-to-card
  payment. The Telegram sales bot: plan selection → receipt review →
  automatic `admins.cfg` updates via RCON → daily VIP expiry.
  - The bot MUST run on the same machine as the server (RCON + file paths).
  - `ADMINS_CFG` path must be set in config (code default was a Windows path).
  - Non-Steam server: watch for duplicate SteamIDs at peak hours (`status`);
    if duplicated, the bot needs to become IP-based.
- `adminmenu_custom.txt` (adds `!vn`/`!vg`/`!vw` VIP commands into SourceMod's
  built-in `/admin` menu) was prepared 2026-10-15; install only on Ali's yes.

## FastDL / skins

- Permanent pack links (never expire):
  - http://3.128.226.176/cso2-weapon-pack-v34.zip (CSO2 weapons, v34-converted)
  - http://3.128.226.176/green-vs-red-player-pack.rar (player models)

## Backups

- `/root/duel/muse/` holds a tested backup daemon (6-hour git-based backups,
  `gc --prune=now`, local size cap) + systemd service/timer + `install.sh`.
  NOTE: its configured paths were mostly `~/.hermes/*`, which no longer exist
  (Hermes was fully removed 2026-10-15 on Ali's order). Re-point the paths
  before installing, or it backs up nothing.

## Ali's Telegram selfbot (HANDS OFF without explicit order)

- Live at `/root/selfbots/acc2/selfbot.py` (selfbot v2), session
  `mine_session.session`, runs as PID-managed nohup. Original backed up at
  `/root/selfbots/acc2_orig_2026-10-15`.
- v2 fixed a critical latent bug in the original: `event.id` does not exist on
  Telethon's `NewMessage.Event`, so the original's message cache crashed on
  every message and anti-delete/anti-edit never actually worked. v2 uses
  `event.message.id`.
- Commands are Persian with `.`/`!`/`/` prefixes; `.پنل` lists them all.
  Notable: `.افک`, `.زمانبندی`, `.آمار`, `.اذان [شهر]`, `.پاکسازی`,
  `.ریستارت`, `.تست`, `.حساب` (safe AST evaluator), `.سنگ کاغذ قیچی`.
- State persists in JSON (survives restarts); message cache is LRU-capped at
  5000; FloodWait is handled with backoff; single-instance via flock;
  API_ID/API_HASH come from env/`.env`, never hardcoded.
- Ali ordered on 2026-10-15: never touch the original files; all duel work used
  copies only. Do not restart/replace it unless he asks.

## Standing preferences

- Provider/product lists: cheapest → most expensive.
- When asking for a list, order it cheapest to most expensive (he asked twice).
- Ask ONE clarifying question before building on an ambiguous request —
  that single question is what made the skin-pack delivery smooth.
