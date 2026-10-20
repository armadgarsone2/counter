# --- Telegram ---
BOT_TOKEN = "CHANGE_ME"

# فقط علی
ADMIN_IDS = [8919463182]

# --- سرور ---
SERVER_NAME = "سفیدان | Wh1Tes"
SERVER_ADDR = "13.53.151.178:27015"

# --- RCON ---
RCON_HOST = "127.0.0.1"
RCON_PORT = 27015
RCON_PASSWORD = "CHANGE_ME"

# --- مسیرها (سوئد) ---
BASE_DIR = "/opt/counter/server"
CSTRIKE_DIR = BASE_DIR + "/cstrike"
MAPS_DIR = CSTRIKE_DIR + "/maps"
SERVER_CFG = CSTRIKE_DIR + "/cfg/server.cfg"
ADMINS_FILE = CSTRIKE_DIR + "/addons/sourcemod/configs/admins_simple.ini"

SERVICE_NAME = "css34.service"
BINARY_NAME = "srcds_i486"
FASTDL_URL = "http://13.53.151.178/cstrike/"

MAPS = [
    "de_dust2", "de_inferno", "de_nuke", "de_train",
    "de_aztec", "de_cbble", "de_piranesi", "de_port",
    "cs_office", "cs_italy", "cs_assault", "cs_havana",
    "de_dust", "fy_pool_day", "awp_map",
]

MANAGED_PLUGINS = [
    ("🔫 GunGame", "gungame"),
    ("🔊 Quake Sounds", "quake_sounds"),
    ("💤 AFK Manager", "afk_manager"),
    ("💥 Damage Display", "damage_display"),
    ("🏆 Simple Rank", "simple_rank"),
]
