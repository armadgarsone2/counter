<div align="center">

[🇮🇷 فارسی](README.md) • [🇬🇧 English](README.en.md) • [🇷🇺 Русский](README.ru.md) • [🇹🇷 Türkçe](README.tr.md)

<p align="center"><img src="assets/banner.jpg" alt="Sefidan | Wh1Tes — Counter-Strike: Source v34" width="100%"></p>
<p align="center">🌐 <a href="https://armadgarsone2.github.io/counter/en/">Server Website</a></p>


# 🦁 Sefidan | Wh1Tes

### ⚔️ Counter-Strike: Source v34 — a friends' server, no mercy ⚔️

![Game](https://img.shields.io/badge/Game-CS%3AS%20v34-orange?style=for-the-badge)
![SourceMod](https://img.shields.io/badge/SourceMod-1.7.3--css34-blue?style=for-the-badge)
![Tickrate](https://img.shields.io/badge/Tickrate-100-red?style=for-the-badge)
![Location](https://img.shields.io/badge/Server-Sweden%20🇸🇪-yellow?style=for-the-badge)
![Players](https://img.shields.io/badge/Players-32-green?style=for-the-badge)

**Real Modern Warfare player models, max money every round, zero freeze time — round starts, fight starts.**

```
connect 13.53.151.178:27015
```

</div>

---

## 🔥 What's inside?

| Feature | Details |
|---|---|
| 🎭 **Real player models** | Ghost, TF141, Gorka, Juggernaut and Spetsnaz — real models, not recolors |
| 💰 **Max money every round** | Every round starts with **$16,000** for everyone — no more money whining |
| 🧊 **Freeze time: zero** | The round starts, the action starts. No standing around |
| 🎯 **Live damage display** | Every hit shows under your crosshair: HP and Armor dealt + enemy's remaining HP |
| 💣 **Bomb Info** | C4 timer + your distance to the bomb + damage you'll take — do the math before you blow up |
| 🌫️ **Dense smoke** | A smoke grenade that actually smokes. Nobody sees through it |
| 📜 **In-game menu `!smenu`** | Server rules and info, right inside the game |
| 🛡️ **Admin panel `!admin`** | Full server management from in-game |
| 🏆 **Ranks & stats** | `!rank` — who frags, who feeds |
| 🔊 **Quake Sounds + music** | Kill effects and join music |

---

## 🎭 The models

| Team | Class | Model |
|---|---|---|
| CT | GIGN | 👻 **MW2 Ghost** |
| CT | GSG9 / SAS / Urban | 🎖️ **TF141** |
| T | Phoenix | 🪖 **Gorka** |
| T | Leet | 🔫 **Russian Mercenary** |
| T | Guerilla | 🐗 **Juggernaut** |
| T | Arctic | ❄️ **MW3 Spetsnaz** |

Models are applied per-class by the **Wh1Tes Models** plugin from dedicated paths and download automatically over FastDL — just connect and play.

> ⚠️ Weapons are 100% stock. Around here, skill does the talking, not gun skins.

---

## 📜 House rules

```
1. No insults or flaming other players
2. No cheats, scripts or bug abuse
3. No mic/chat spam
4. No camping behind the enemy spawn
5. Respect the admins
```

---

## 🗂️ Repository layout

```
counter/
├── README.md                  ← you are here (Persian main version)
├── README.en.md / README.ru.md / README.tr.md
├── server/                    ← the whole server, ready to run
│   ├── srcds_run
│   └── cstrike/
│       ├── cfg/               ← configs + game modes (gamemodes)
│       ├── addons/sourcemod/
│       │   ├── plugins/       ← compiled plugins (.smx)
│       │   ├── scripting/     ← plugin sources (.sp) — the wh1tes folder is our custom work
│       │   └── configs/
│       └── maps/  models/  materials/  sound/
├── css-bot/                   ← Telegram management bot (RCON, game modes, backups)
├── tools/                     ← analysis/build scripts + systemd service
├── skills/                    ← server-management skills (living docs of hard lessons)
└── docs/                      ← detailed guides
```

---

## 🚀 Quick start

```bash
# 1. Clone
git clone https://github.com/armadgarsone2/counter.git
cd counter/server

# 2. Make executable
chmod +x srcds_run bin/*

# 3. ⚠️ Change the RCON password (the file ships with CHANGE_ME)
nano cstrike/cfg/server.cfg

# 4. Run
./srcds_run -game cstrike +map de_dust2 -maxplayers 32 -port 27015 +tickrate 100

# 5. (Optional) run as a service
sudo cp ../tools/css34.service /etc/systemd/system/
sudo systemctl enable --now css34
```

**FastDL:** files are served by nginx so players pull the models at full speed:

```
sv_downloadurl "http://YOUR_SERVER_IP/cstrike/"
```

---

## 🧩 Custom plugins (Wh1Tes)

| Plugin | What it does |
|---|---|
| **Wh1Tes Models** | Real per-class models + optimized downloads table |
| **Wh1Tes Round Money** | $16,000 every round + zero freeze time (classic rules) |
| **Wh1Tes Damage Info** | HP/Armor dealt, shown under the crosshair |
| **Wh1Tes Dense Smoke** | Denser smoke grenades |
| **Bomb Info** | Bomb timer, distance and damage |

Plus: admin panel, server menu, ranks, AFK manager, connect messages, Quake Sounds and a Telegram management bot.

---

## ⚙️ Under the hood (for the technical crowd)

- This old build only runs plugins compiled with **SourceMod 1.9** reliably; 1.12 won't load, 1.10 segfaults. Golden rule.
- The downloads table has a ceiling: overload it and real clients crash on connect. Keep the list exact and lean.
- Resolve material paths from .mdl files **case-insensitively**; Linux takes case seriously, and the failure mode is purple players.
- Raw Persian text renders broken in this engine — write English or reshape it properly first.
- The full war stories live in `skills/`.

---

<div align="center">

**A friends-only, non-commercial server — no VIP shop, just the boys.** 🤝

Built with ☕ and 🎧 on a small box in Stockholm

</div>

---

### 🔎 Keywords

Counter-Strike: Source v34 dedicated server (srcds) — full server package with SourceMod 1.7.3 plugins, Metamod, custom player models (MW2 Ghost, TF141, Gorka, Juggernaut, MW3 Spetsnaz), FastDL, classic game mode, Telegram admin bot and Persian documentation. Download a ready-to-run CS:S v34 server for Linux.
