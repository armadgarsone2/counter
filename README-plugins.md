# CS:S Server Plugins + Telegram Bot

Live plugin set and bot source from a friends-only Counter-Strike: Source
(v34) server — «سفیدان | Wh1Tes».

## Contents

- `scripting/` — SourceMod plugin sources (`.sp`), including the custom
  Wh1Tes plugins and stock SourceMod sources.
- `plugins/` — Compiled plugins (`.smx`). `plugins/disabled/` holds the
  ones not loaded by default (GunGame set, old skin systems, retired
  damage display, vote plugins).
- `css-bot/` — Telegram management bot source (`bot.py`, `audit.py`,
  `leaderboard.py`, `rcon.py`). The bot talks to the game server over
  local RCON.

## Notes

- Sanitized for public release: `config.py`, all `*.cfg` files, admin
  files, logs, databases, backups and session files are NOT included.
  The bot's `OWNER_ID` is redacted — set your own Telegram user ID.
- Some plugins are inert on this No-Steam build (e.g. `wh1tes_gamedesc`:
  its game-description hook never fires; the server-list game name comes
  from a binary patch instead).
- GunGame is event-only: its plugins live in `plugins/disabled/` and are
  loaded on demand.
- Plugin versions in this snapshot are the live, arena-reviewed ones
  (Admin Panel 3.3, Modes 0.5.2, Rank 1.1.1, Shop 1.2.1, Kill Overlay
  1.3.4, G7 Props 1.0.7, Damage Info 1.2.1).
