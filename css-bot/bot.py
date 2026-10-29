#!/usr/bin/env python3
"""🎮 Ultimate Telegram bot for Counter-Strike: Source server management.

The best of both worlds:
  - Rock-solid pure-Python RCON (no external deps, fixed packet sizing)
  - Full admin panel: dashboard, players, maps, plugins, VIP, quick cmds
  - Security: admin check on EVERY handler, token redacted in logs,
    no shell injection (systemctl via argv, never shell)
  - Watchdog: auto-restarts crashed server, respects manual stops

15 features: dashboard, players+ping, kick/ban/slay/slap/mute, VIP grant,
map changer (auto-scan), plugin mgmt, VIP/admin file mgmt, quick commands,
power control, broadcast, RCON console, auto RCON password, FastDL check,
watchdog, resource monitor.
"""

import asyncio
import glob
import json
import logging
import os
import re
import secrets
import sqlite3
import string
import time
import traceback
import uuid

from telegram import BotCommand, InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.constants import ParseMode
from telegram.ext import (
    ApplicationBuilder,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    ConversationHandler,
    MessageHandler,
    filters,
)

from rcon import RCON, RCONError, RCONAuthError, parse_status
import audit
import leaderboard
import config

# ---------------------------------------------------------------- logging
# Redact the bot token from every log record so it never lands in bot.log.


class _TokenFilter(logging.Filter):
    def filter(self, record):
        try:
            token = config.BOT_TOKEN
            if token and isinstance(record.msg, str) and token in record.msg:
                record.msg = record.msg.replace(token, "[BOT_TOKEN]")
            if record.args:
                args = tuple(
                    str(a).replace(token, "[BOT_TOKEN]")
                    if isinstance(a, str) else a
                    for a in (record.args if isinstance(record.args, tuple)
                              else (record.args,))
                )
                record.args = args
            # Tracebacks are formatted AFTER filters run, so exc_text
            # would otherwise carry the token (e.g. Bot API URLs in
            # telegram-library errors). Pre-render + redact it here.
            if record.exc_info and record.exc_info[0] is not None:
                exc_text = "".join(
                    traceback.format_exception(*record.exc_info))
                if token:
                    exc_text = exc_text.replace(token, "[BOT_TOKEN]")
                record.exc_text = exc_text
                record.exc_info = None
        except Exception:
            pass
        return True


logging.basicConfig(
    format="%(asctime)s %(levelname)s %(message)s", level=logging.INFO)
for _h in logging.root.handlers:
    _h.addFilter(_TokenFilter())
for _n in ("httpx", "httpcore", "telegram", "telegram.ext"):
    logging.getLogger(_n).setLevel(logging.WARNING)

log = logging.getLogger("css-ultimate")

ASK_SAY, ASK_RCON, ASK_BAN_TIME, ASK_VIP, ASK_TADM, ASK_ADS_ADD, \
    ASK_ADS_EDIT = range(7)

_ERROR_RE = re.compile(
    r"unknown command|invalid|error|failed|cannot|no such|"
    r"no matching client|could not find|not found|"
    r"player not found|no such player|bad |usage:|"
    r"is not |invalid ",
    re.I)
# separator that never appears in SteamIDs / map names
_SEP = "|"


# ---------------------------------------------------------------- config helpers

def get_rcon_password():
    """Read RCON password from server.cfg, fall back to config."""
    try:
        with open(config.SERVER_CFG, encoding="utf-8",
                  errors="ignore") as f:
            for line in f:
                s = line.strip()
                if s.startswith("rcon_password") and not s.startswith("//"):
                    parts = s.split(None, 1)
                    if len(parts) > 1:
                        return parts[1].strip('" ')
    except OSError:
        pass
    return config.RCON_PASSWORD


def _rcon_client():
    return RCON(config.RCON_HOST, config.RCON_PORT, get_rcon_password())


async def arcon(cmd):
    def _run():
        with _rcon_client() as rc:
            return rc.command(cmd)
    return await asyncio.to_thread(_run)


async def safe_rcon(cmd):
    try:
        result = await arcon(cmd)
        audit.maybe_log(cmd)
        return True, result
    except RCONAuthError:
        return False, "❌ پسورد RCON اشتباه است."
    except RCONError as e:
        return False, f"❌ خطا در اتصال به سرور: {e}"
    except Exception as e:  # noqa: BLE001
        log.exception("rcon failed")
        return False, f"❌ خطای غیرمنتظره: {e}"


def cmd_failed(output):
    return bool(_ERROR_RE.search(output or ""))


# ------------------------------------------------------------ bot admins (v2)
# Owner is fixed; extra Telegram admins persist in bot_admins.json and can
# use the bot but can NOT manage admins (owner-only section).
OWNER_ID = 0  # <-- put your own Telegram user ID here
_BOT_DIR = os.path.dirname(os.path.abspath(__file__))
_ADMINS_JSON = os.path.join(_BOT_DIR, "bot_admins.json")
_STATE_JSON = os.path.join(_BOT_DIR, "bot_state.json")


def _load_json(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def _save_json(path, data):
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f)
    except OSError:
        pass


BOT_ADMINS = set(_load_json(_ADMINS_JSON, []))
BOT_STATE = _load_json(_STATE_JSON, {"notifier": True, "bridge": False,
                                     "card_chat": 0, "card_msg": 0})


def save_bot_admins():
    _save_json(_ADMINS_JSON, sorted(BOT_ADMINS))


def save_bot_state():
    _save_json(_STATE_JSON, BOT_STATE)


def is_owner(uid):
    return uid == OWNER_ID


def is_admin(uid):
    return uid == OWNER_ID or uid in BOT_ADMINS or uid in config.ADMIN_IDS


def _safe_int(text):
    """int() that fails closed: bad callback data -> None, never raises."""
    try:
        return int(text)
    except (TypeError, ValueError):
        return None


def esc(text):
    """Escape for HTML parse mode (prevents Markdown/HTML breakage)."""
    return (str(text).replace("&", "&amp;")
            .replace("<", "&lt;").replace(">", "&gt;"))


# ---------------------------------------------------------------- keyboards

def kb_main(uid=None):
    rows = [
        [InlineKeyboardButton("🔄 بروزرسانی", callback_data="nav_home"),
         InlineKeyboardButton("👥 بازیکن‌ها", callback_data="nav_players")],
        [InlineKeyboardButton("🎮 مودها", callback_data="nav_modes"),
         InlineKeyboardButton("🗺️ تعویض مپ", callback_data="nav_maps")],
        [InlineKeyboardButton("🧩 پلاگین‌ها", callback_data="nav_plugins"),
         InlineKeyboardButton("🌟 VIP / ادمین", callback_data="nav_vips")],
        [InlineKeyboardButton("📣 اعلان‌ها", callback_data="nav_ads"),
         InlineKeyboardButton("🏆 برترین‌ها", callback_data="nav_top")],
        [InlineKeyboardButton("⚡ دستورات سریع", callback_data="nav_quick"),
         InlineKeyboardButton("🤖 اتوماسیون", callback_data="nav_auto")],
        [InlineKeyboardButton("📢 پیام همگانی", callback_data="act_broadcast"),
         InlineKeyboardButton("⌨️ کنسول RCON", callback_data="act_rcon")],
        [InlineKeyboardButton("📜 سابقه ادمین‌ها", callback_data="nav_history"),
         InlineKeyboardButton("🖥️ منابع", callback_data="nav_resources")],
        [InlineKeyboardButton("🏆 لیدربورد — رنک و اسلحه", callback_data="nav_board")],
        [InlineKeyboardButton("◀️ منو", callback_data="menu")],
    ]
    if uid == OWNER_ID:
        rows.append([InlineKeyboardButton("👥 ادمین تل",
                                          callback_data="nav_tadm")])
    rows.append(
        [InlineKeyboardButton("🟢 Start", callback_data="pwr_start"),
         InlineKeyboardButton("🟡 Restart", callback_data="pwr_restart"),
         InlineKeyboardButton("🔴 Stop", callback_data="pwr_stop")])
    return InlineKeyboardMarkup(rows)


def back_btn():
    return InlineKeyboardMarkup(
        [[InlineKeyboardButton("◀️ منو", callback_data="menu")]])


# ---------------------------------------------------------------- dashboard

async def get_process_stats():
    def _c():
        try:
            import psutil
        except ImportError:
            return None
        target = None
        for p in psutil.process_iter(["name"]):
            try:
                if p.info["name"] and config.BINARY_NAME in p.info["name"]:
                    target = p
                    break
            except Exception:
                continue
        running = target is not None
        cpu, mem = 0.0, 0.0
        if target:
            try:
                target.cpu_percent()  # init sample
            except Exception:
                pass
        time.sleep(0.6)
        if target:
            try:
                cpu = target.cpu_percent()
                mem = target.memory_info().rss / 1024 / 1024
            except Exception:
                pass
        vm = psutil.virtual_memory()
        return {"running": running, "srcds_cpu": cpu,
                "srcds_ram": round(mem, 1),
                "sys_cpu": psutil.cpu_percent(interval=0.3),
                "sys_ram": vm.percent}
    return await asyncio.to_thread(_c)


async def check_fastdl():
    """Check FastDL health.

    Standard Source FastDL layout keeps files under maps/ (often .bz2).
    403 on the directory (no autoindex) still means nginx is UP.
    Only connection errors and 5xx mean DOWN.
    """
    def _c():
        import urllib.request
        import urllib.error
        base = config.FASTDL_URL.rstrip("/")

        def _get(url):
            """True=file ok, 'up'=server answers but file missing,
            False=server down."""
            try:
                req = urllib.request.Request(url, method="GET")
                with urllib.request.urlopen(req, timeout=4) as r:
                    r.read(1)
                    return True if r.status in (200, 206) else "up"
            except urllib.error.HTTPError as e:
                return False if 500 <= e.code < 600 else "up"
            except Exception:
                return False

        for path in ("maps/de_dust2.bsp.bz2", "maps/de_dust2.bsp"):
            st = _get(f"{base}/{path}")
            if st is True:
                return True
            if st is False:
                return False
        return _get(base + "/") is not False
    return await asyncio.to_thread(_c)


async def render_dashboard():
    # load concurrently: total time = slowest, not sum
    stats_t = asyncio.create_task(get_process_stats())
    fastdl_t = asyncio.create_task(check_fastdl())
    rcon_t = asyncio.create_task(safe_rcon("status"))
    stats = await stats_t
    fastdl_ok = await fastdl_t
    ok, out = await rcon_t
    info = parse_status(out) if ok else None

    proc = ("🟢 در حال اجرا" if stats and stats["running"]
            else "🔴 متوقف") if stats else "⚪ نامشخص"
    rcon_st = "🟢 متصل" if info else "🔴 قطع"
    fastdl_st = "🟢 فعال" if fastdl_ok else "🔴 قطع"

    t = (f"🛡 <b>پنل مدیریت {esc(config.SERVER_NAME)}</b>\n"
         f"━━━━━━━━━━━━━━\n"
         f"⚙️ سرور: {proc}\n"
         f"📡 RCON: {rcon_st}\n"
         f"🚀 FastDL: {fastdl_st}\n")
    if stats:
        t += (f"💻 منابع: CPU {stats['srcds_cpu']:.0f}% | "
              f"RAM {stats['srcds_ram']:.0f}M "
              f"(سیستم: CPU {stats['sys_cpu']:.0f}% RAM {stats['sys_ram']:.0f}%)\n")
    t += "━━━━━━━━━━━━━━\n"
    if info:
        t += (f"🗺️ مپ: <code>{esc(info['map'])}</code>\n"
              f"👥 بازیکن: <b>{len(info['players'])}</b>\n"
              f"🔗 <code>{esc(config.SERVER_ADDR)}</code>\n")
    else:
        t += "⚠️ سرور خاموش یا RCON بی‌پاسخ است.\n"
    return t


# ---------------------------------------------------------------- guards

# persistent manual-stop flag (survives bot restarts, unlike bot_data)
_STOP_FLAG = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          ".manual_stop")


def is_manual_stop():
    return os.path.exists(_STOP_FLAG)


def set_manual_stop(on: bool):
    try:
        if on:
            open(_STOP_FLAG, "w").write("1")
        elif os.path.exists(_STOP_FLAG):
            os.remove(_STOP_FLAG)
    except OSError:
        pass


async def guard(q):
    """Admin check for callback queries. Returns True if allowed."""
    if not is_admin(q.from_user.id):
        await q.answer("⛔ دسترسی ندارید.", show_alert=True)
        return False
    audit.set_actor(q.from_user.first_name or "", q.from_user.id)
    return True


async def guard_msg(update: Update):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("⛔ شما دسترسی ندارید.")
        return False
    audit.set_actor(update.effective_user.first_name or "",
                    update.effective_user.id)
    return True


def plugin_loaded(output: str, fname: str) -> bool:
    """Check if a plugin is loaded. Avoids substring false-positives
    (e.g. 'rank' matching 'simple_rank') via word boundaries."""
    low = output.lower()
    f_low = fname.lower()
    if f"{f_low}.smx" in low:          # exact filename
        return True
    if f_low in low and re.search(rf"(?<![\w]){re.escape(f_low)}(?![\w])",
                                  low):
        return True                     # exact token match
    disp = f_low.replace("_", " ")      # display name: "afk manager"
    return re.search(rf"\b{re.escape(disp)}\b", low) is not None


def valid_identity(identity: str):
    """Validate admin identity. Returns (ok, normalized) where normalized
    is the exact string to write in admins_simple.ini.

    SECURITY: STEAM_ID_LAN / STEAM_ID_PENDING are SHARED by many players
    on non-Steam servers — granting them (esp. flag z) would make EVERY
    such player an admin. Always rejected.
    IPs need SourceMod's '!' prefix: '!1.2.3.4'.
    """
    s = (identity or "").strip()
    # Real SteamID: unique per player, safe
    if re.fullmatch(r"STEAM_[0-5]:[0-1]:\d+", s):
        return True, s
    # Shared non-Steam IDs: REJECT (would grant to all holders)
    if s in ("STEAM_ID_LAN", "STEAM_ID_PENDING"):
        return False, ""
    # IP address: accept with or without '!', normalize to '!ip'
    ip = s.lstrip("!")
    if re.fullmatch(r"\d{1,3}(\.\d{1,3}){3}", ip):
        if all(0 <= int(p) <= 255 for p in ip.split(".")):
            return True, f"!{ip}"
    return False, ""

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return
    await context.bot.send_chat_action(update.effective_chat.id, "typing")
    text = await render_dashboard()
    await update.message.reply_text(text, parse_mode=ParseMode.HTML,
                                    reply_markup=kb_main(update.effective_user.id))


async def on_button(update: Update, context: ContextTypes.DEFAULT_TYPE):
    q = update.callback_query
    # NOTE: exactly ONE q.answer() per callback path (Telegram rejects a 2nd).
    if not await guard(q):
        return ConversationHandler.END
    data = q.data
    # Navigation callbacks get a plain ack here; action callbacks
    # (pact/plg/setmap/qcmd/vipreload) answer themselves with show_alert.
    _action_prefixes = (f"pact{_SEP}", f"setmap{_SEP}", f"plg{_SEP}",
                        "qcmd|", "vipreload", "mode|", "gnight_yes",
                        "mkadm|", "ads_delyes|", "tadm_delyes|", "auto|")
    if not data.startswith(_action_prefixes):
        try:
            await q.answer()
        except Exception:
            pass

    if data in ("menu", "nav_home"):
        text = await render_dashboard()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb_main(q.from_user.id))
        except Exception:
            pass  # message not modified — already fresh
        return ConversationHandler.END

    # ---- players ------------------------------------------------
    if data == "nav_players":
        ok, out = await safe_rcon("status")
        if not ok:
            await q.edit_message_text(out, reply_markup=back_btn())
            return ConversationHandler.END
        players = parse_status(out)["players"]
        if not players:
            await q.edit_message_text("👻 هیچ بازیکنی آنلاین نیست.",
                                      reply_markup=back_btn())
            return ConversationHandler.END
        kb = [[InlineKeyboardButton(
            f"👤 {p['name']} | 📶 {p.get('ping', '?')}ms",
            callback_data=f"pl{_SEP}{p['id']}")] for p in players[:25]]
        kb += [[InlineKeyboardButton("🔄 رفرش", callback_data="nav_players"),
                InlineKeyboardButton("◀️ منو", callback_data="menu")]]
        await q.edit_message_text("👥 <b>بازیکن‌ها</b> — یکی رو انتخاب کن:",
                                  parse_mode=ParseMode.HTML,
                                  reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith(f"pl{_SEP}"):
        uid = data.split(_SEP, 1)[1]
        ok, out = await safe_rcon("status")
        players = parse_status(out)["players"] if ok else []
        tgt = next((p for p in players if p["id"] == uid), None)
        if not tgt:
            # already acked at top of on_button -> just edit, no 2nd answer
            await q.edit_message_text("❌ این بازیکن از سرور خارج شده است!",
                                      reply_markup=back_btn())
            return ConversationHandler.END
        sid = tgt.get("steamid", "")
        is_real_steam = bool(re.fullmatch(r"STEAM_[0-5]:[0-1]:\d+", sid))
        pip = tgt.get("ip", "")
        kb = [
            [InlineKeyboardButton("👢 Kick",
                                 callback_data=f"pact{_SEP}kick{_SEP}{uid}"),
             InlineKeyboardButton("🔨 Ban",
                                 callback_data=f"pact{_SEP}ban{_SEP}{uid}"),
             InlineKeyboardButton("💀 Slay",
                                 callback_data=f"pact{_SEP}slay{_SEP}{uid}")],
            [InlineKeyboardButton("👋 Slap",
                                 callback_data=f"pact{_SEP}slap{_SEP}{uid}"),
             InlineKeyboardButton("🔇 Mute",
                                 callback_data=f"pact{_SEP}mute{_SEP}{uid}")],
        ]
        # VIP: real SteamID -> direct; otherwise offer VIP by IP
        if is_real_steam:
            kb.append([InlineKeyboardButton(
                "🌟 اعطای VIP",
                callback_data=f"pact{_SEP}vip{_SEP}{sid}")])
        elif pip:
            kb.append([InlineKeyboardButton(
                f"🌟 VIP با IP ({pip})",
                callback_data=f"pact{_SEP}vip{_SEP}!{pip}")])
        kb.append([InlineKeyboardButton(
            "🔀 تعویض تیم", callback_data=f"pact{_SEP}swap{_SEP}{uid}")])
        if tgt["name"] in _game_admin_names():
            kb.append([InlineKeyboardButton(
                "🗑 حذف ادمین بازی",
                callback_data=f"pact{_SEP}rmadmin{_SEP}{uid}")])
        else:
            kb.append([InlineKeyboardButton(
                "👑 ادمین کن",
                callback_data=f"pact{_SEP}mkadmin{_SEP}{uid}")])
        kb.append([InlineKeyboardButton("🔙 لیست",
                                        callback_data="nav_players")])
        await q.edit_message_text(
            f"🎯 <b>{esc(tgt['name'])}</b>\n"
            f"🆔 #{esc(uid)} | 🎮 <code>{esc(sid)}</code>"
            + (f" | 🌐 <code>{esc(pip)}</code>" if pip else ""),
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith(f"pact{_SEP}"):
        _, action, target = data.split(_SEP, 2)
        if action == "vip":
            # validate identity (SteamID or IP; shared LAN/PENDING rejected)
            ok_id, norm_id = valid_identity(target)
            if not ok_id:
                await q.answer("❌ شناسه معتبر نیست.", show_alert=True)
                return ConversationHandler.END
            if norm_id.startswith("!"):
                # IP grant: same CGNAT confirmation as the typed VIP flow
                vid = uuid.uuid4().hex[:8]
                context.user_data["pending_vip"] = {
                    "vid": vid, "identity": norm_id, "flag": "o"}
                await q.answer()
                kb = [[InlineKeyboardButton("✅ بله، مطمئنم",
                                            callback_data=f"vipconfirm|{vid}|yes"),
                       InlineKeyboardButton("❌ لغو",
                                            callback_data=f"vipconfirm|{vid}|no")]]
                await q.edit_message_text(
                    f"⚠️ <b>توجه</b>\n\nداری به IP <code>{esc(norm_id)}</code> دسترسی "
                    f"<b>VIP (o)</b> می‌دی.\n\nاگه این IP مشترک (CGNAT) باشه، همه‌ی کسایی که پشتش هستن "
                    f"VIP می‌گیرن. مطمئنی؟",
                    parse_mode=ParseMode.HTML,
                    reply_markup=InlineKeyboardMarkup(kb))
                return ConversationHandler.END
            res = await add_vip(norm_id, "o", "VIP via Telegram")
            await q.answer(res, show_alert=True)
            return ConversationHandler.END
        if action == "ban":
            # ask for duration first (restores ASK_BAN_TIME flow)
            context.user_data["ban_uid"] = target
            try:
                await q.answer()  # single ack; pact| has no top ack
            except Exception:
                pass
            await q.edit_message_text(
                "🔨 مدت بن رو به دقیقه بفرست (0 = دائمی):",
                reply_markup=back_btn())
            return ASK_BAN_TIME
        if action == "swap":
            ok, out = await safe_rcon(f"sm_bot_swap {target}")
            if ok and "BOTSWAP_OK" in out:
                await q.answer("🔀 تیمش عوض شد.", show_alert=True)
            else:
                await q.answer(f"❌ نشد: {out[:110]}", show_alert=True)
            return ConversationHandler.END
        if action in ("mkadmin", "rmadmin"):
            ok2, out2 = await safe_rcon("status")
            players2 = parse_status(out2)["players"] if ok2 else []
            tgt2 = next((p for p in players2 if p["id"] == target), None)
            if not tgt2:
                await q.answer("❌ این بازیکن از سرور رفته.",
                               show_alert=True)
                return ConversationHandler.END
            nonce = uuid.uuid4().hex[:8]
            if action == "mkadmin":
                pw = "".join(secrets.choice(
                    string.ascii_letters + string.digits) for _ in range(10))
                context.user_data["pending_gadm"] = {
                    "nonce": nonce, "kind": "add",
                    "name": tgt2["name"], "pw": pw}
                await q.answer()
                kb2 = [[InlineKeyboardButton(
                    "✅ بله، ادمینش کن", callback_data=f"mkadm|{nonce}|yes"),
                    InlineKeyboardButton(
                    "❌ لغو", callback_data=f"mkadm|{nonce}|no")]]
                await q.edit_message_text(
                    f"👑 <b>{esc(tgt2['name'])}</b> ادمین کامل سرور "
                    f"(فلگ z) بشه؟\n\n"
                    f"🔑 پسورد ساخته‌شده: <code>{esc(pw)}</code>\n"
                    "این پسورد رو بهش بده؛ یه بار تو کنسول بازی بزنه:\n"
                    f"<code>setinfo _password {esc(pw)}</code>",
                    parse_mode=ParseMode.HTML,
                    reply_markup=InlineKeyboardMarkup(kb2))
            else:
                context.user_data["pending_gadm"] = {
                    "nonce": nonce, "kind": "del", "name": tgt2["name"]}
                await q.answer()
                kb2 = [[InlineKeyboardButton(
                    "✅ بله، حذفش کن", callback_data=f"mkadm|{nonce}|yes"),
                    InlineKeyboardButton(
                    "❌ لغو", callback_data=f"mkadm|{nonce}|no")]]
                await q.edit_message_text(
                    f"🗑 دسترسی ادمین بازی <b>{esc(tgt2['name'])}</b> "
                    "حذف بشه؟",
                    parse_mode=ParseMode.HTML,
                    reply_markup=InlineKeyboardMarkup(kb2))
            return ConversationHandler.END
        cmds = {
            "kick": f"sm_kick #{target} \"Kicked by admin\"",
            "slay": f"sm_slay #{target}",
            "slap": f"sm_slap #{target} 10",
            "mute": f"sm_silence #{target}",
        }
        ok, out = await safe_rcon(cmds[action])
        if not ok or cmd_failed(out):
            await q.answer(f"❌ نشد: {out[:120]}", show_alert=True)
        else:
            await q.answer(f"✅ {action} روی #{target} اجرا شد.",
                           show_alert=True)
        return ConversationHandler.END

    # ---- leaderboard (rank + weapons) ------------------------------
    if data == "nav_board" or data.startswith("boardw|"):
        if data == "nav_board":
            text, kb = leaderboard.render_main()
        else:
            text, kb = leaderboard.render_weapon(data.split("|", 1)[1])
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    # ---- admin action history ------------------------------------
    if data == "nav_history":
        text = audit.render_history(15)
        kb = InlineKeyboardMarkup([
            [InlineKeyboardButton("🔄 بروزرسانی", callback_data="nav_history")],
            [InlineKeyboardButton("◀️ منو", callback_data="menu")]])
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    # ---- maps (paginated) ---------------------------------------
    if data == "nav_maps" or data.startswith("mapspage|"):
        page = 0
        if "|" in data:
            parsed = _safe_int(data.split("|", 1)[1])
            page = parsed if parsed is not None else 0
        maps = get_installed_maps()
        per_page = 20
        pages = max(1, (len(maps) + per_page - 1) // per_page)
        page = max(0, min(page, pages - 1))
        chunk = maps[page * per_page:(page + 1) * per_page]
        kb, row = [], []
        for m in chunk:
            row.append(InlineKeyboardButton(f"🗺️ {m}",
                                            callback_data=f"setmap{_SEP}{m}"))
            if len(row) == 2:
                kb.append(row)
                row = []
        if row:
            kb.append(row)
        nav = []
        if page > 0:
            nav.append(InlineKeyboardButton("◀️ قبلی",
                                            callback_data=f"mapspage|{page-1}"))
        if page < pages - 1:
            nav.append(InlineKeyboardButton("بعدی ▶️",
                                            callback_data=f"mapspage|{page+1}"))
        if nav:
            kb.append(nav)
        kb.append([InlineKeyboardButton("◀️ منو", callback_data="menu")])
        await q.edit_message_text(
            f"🗺️ <b>مپ‌ها ({len(maps)})</b> — صفحه {page+1}/{pages}:",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith(f"setmap{_SEP}"):
        m = data.split(_SEP, 1)[1]
        # validate: only known maps, no injection
        if m not in get_installed_maps():
            await q.answer("❌ مپ نامعتبر.", show_alert=True)
            return ConversationHandler.END
        ok, out = await safe_rcon(f"changelevel {m}")
        if not ok or cmd_failed(out):
            await q.answer(f"❌ نشد: {out[:120]}", show_alert=True)
        else:
            await q.answer(f"🗺️ مپ عوض شد به {m}", show_alert=True)
            text = await render_dashboard()
            try:
                await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                          reply_markup=kb_main(q.from_user.id))
            except Exception:
                pass
        return ConversationHandler.END

    # ---- plugins ------------------------------------------------
    if data == "nav_plugins":
        ok, out = await safe_rcon("sm plugins list")
        kb = []
        if ok and out.strip():
            for title, fname in config.MANAGED_PLUGINS:
                loaded = plugin_loaded(out, fname)
                icon = "🟢" if loaded else "🔴"
                act = "unload" if loaded else "load"
                kb.append([
                    InlineKeyboardButton(f"{icon} {title}",
                                         callback_data=f"plg{_SEP}{act}"
                                         f"{_SEP}{fname}"),
                    InlineKeyboardButton("🔄",
                                         callback_data=f"plg{_SEP}reload"
                                         f"{_SEP}{fname}"),
                ])
        else:
            kb.append([InlineKeyboardButton(
                "⚠️ خروجی پلاگین‌ها خالیه", callback_data="noop")])
        kb.append([InlineKeyboardButton("◀️ منو", callback_data="menu")])
        await q.edit_message_text("🧩 <b>پلاگین‌ها</b> — کلیک = روشن/خاموش:",
                                  parse_mode=ParseMode.HTML,
                                  reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith(f"plg{_SEP}"):
        _, action, plugin = data.split(_SEP, 2)
        if plugin not in [f for _, f in config.MANAGED_PLUGINS]:
            await q.answer("❌ پلاگین نامعتبر.", show_alert=True)
            return ConversationHandler.END
        if plugin == "gungame":
            gg = ["gungame_config", "gungame", "gungame_afk", "gungame_bot",
                  "gungame_display_winner", "gungame_logging",
                  "gungame_mapvoting", "gungame_stats", "gungame_tk"]
            if action == "load":
                cmds = [f"sm plugins load disabled/{g}" for g in gg]
            elif action == "unload":
                cmds = [f"sm plugins unload {g}" for g in gg]
            else:
                cmds = [f"sm plugins reload {g}" for g in gg]
            ok, out = True, ""
            for c in cmds:
                ok1, out1 = await safe_rcon(c)
                if not ok1 or cmd_failed(out1):
                    ok, out = False, out1
        else:
            ok, out = await safe_rcon(f"sm plugins {action} {plugin}")
        await q.answer("✅ اجرا شد." if ok and not cmd_failed(out)
                       else f"❌ نشد: {out[:120]}", show_alert=True)
        return ConversationHandler.END

    # ---- VIP / admin --------------------------------------------
    if data == "nav_vips":
        last = read_admins_tail()
        kb = [
            [InlineKeyboardButton("➕ VIP جدید (فلگ o)",
                                 callback_data="vipadd|o"),
             InlineKeyboardButton("👑 ادمین (فلگ z)",
                                 callback_data="vipadd|z")],
            [InlineKeyboardButton("🗑 حذف ادمین بازی",
                                 callback_data="nav_rmadmin")],
            [InlineKeyboardButton("🔄 ریلود ادمین‌ها",
                                 callback_data="vipreload"),
             InlineKeyboardButton("◀️ منو", callback_data="menu")],
        ]
        await q.edit_message_text(
            f"🌟 <b>VIP / ادمین</b>\n<code>{esc(last)}</code>",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("vipadd|"):
        context.user_data["vip_flag"] = data.split("|", 1)[1]
        await q.edit_message_text(
            "🆔 SteamID رو بفرست (مثلاً <code>STEAM_0:1:123456</code>):",
            parse_mode=ParseMode.HTML, reply_markup=back_btn())
        return ASK_VIP

    if data.startswith("vipconfirm|"):
        _, vid, choice = data.split("|", 2)
        pending = context.user_data.pop("pending_vip", None)
        # nonce must match: a stale "yes" from an older message can't
        # confirm a newer pending
        if not pending or pending.get("vid") != vid or choice != "yes":
            await q.edit_message_text("لغو شد.", reply_markup=back_btn())
            return ConversationHandler.END
        identity, flag = pending["identity"], pending["flag"]
        res = await add_vip(identity, flag, "Added via Telegram (confirmed)")
        note = ("\n\n⚠️ یادت باشه: این IP ممکنه عوض/مشترک بشه."
                if identity.startswith("!") else "")
        await q.edit_message_text(f"{res}{note}",
                                  reply_markup=back_btn())
        return ConversationHandler.END

    if data == "nav_rmadmin":
        names = sorted(_game_admin_names())
        if not names:
            await q.edit_message_text(
                "🗑 <b>حذف ادمین بازی</b>\n\nادمینی تو فایل نیست.",
                parse_mode=ParseMode.HTML, reply_markup=back_btn())
            return ConversationHandler.END
        context.user_data["rm_names"] = names
        kb = [[InlineKeyboardButton(f"🗑 {n}",
                                    callback_data=f"rmadm|{i}")]
              for i, n in enumerate(names)]
        kb.append([InlineKeyboardButton("◀️ برگشت",
                                        callback_data="nav_vips")])
        await q.edit_message_text(
            "🗑 <b>حذف ادمین بازی</b>\n\nکدوم ادمین حذف بشه؟",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("rmadm|"):
        idx = _safe_int(data.split("|", 1)[1])
        if idx is None:
            await q.answer("❌ لیست قدیمی شده؛ دوباره بازش کن.",
                           show_alert=True)
            return ConversationHandler.END
        names = (context.user_data.get("rm_names")
                 or sorted(_game_admin_names()))
        if not (0 <= idx < len(names)):
            await q.answer("❌ لیست قدیمی شده؛ دوباره بازش کن.",
                           show_alert=True)
            return ConversationHandler.END
        nonce = uuid.uuid4().hex[:8]
        context.user_data["pending_rm"] = {"nonce": nonce,
                                           "name": names[idx]}
        kb = InlineKeyboardMarkup([[
            InlineKeyboardButton("✅ بله، حذفش کن",
                                 callback_data=f"rmconfirm|{nonce}|yes"),
            InlineKeyboardButton("❌ لغو",
                                 callback_data=f"rmconfirm|{nonce}|no")]])
        await q.edit_message_text(
            f"🗑 دسترسی ادمین بازی <b>{esc(names[idx])}</b> حذف بشه؟",
            parse_mode=ParseMode.HTML, reply_markup=kb)
        return ConversationHandler.END

    if data.startswith("rmconfirm|"):
        _, nonce, choice = data.split("|", 2)
        pending = context.user_data.pop("pending_rm", None)
        if not pending or pending.get("nonce") != nonce or choice != "yes":
            await q.edit_message_text("لغو شد.", reply_markup=back_btn())
            return ConversationHandler.END
        res = await remove_game_admin(pending["name"])
        await q.edit_message_text(res, reply_markup=back_btn())
        return ConversationHandler.END

    if data == "vipreload":
        ok, out = await safe_rcon("sm_reloadadmins")
        await q.answer("✅ ریلود شد." if ok else f"❌ {out[:100]}",
                       show_alert=True)
        return ConversationHandler.END

    # ---- quick commands ------------------------------------------
    if data == "nav_quick":
        kb = [
            [InlineKeyboardButton("♻️ ریستارت راند",
                                 callback_data="qcmd|mp_restartgame 1"),
             InlineKeyboardButton("💰 پول 16k",
                                 callback_data="qcmd|mp_startmoney 16000")],
            [InlineKeyboardButton("🗣️ AllTalk روشن",
                                 callback_data="qcmd|sv_alltalk 1"),
             InlineKeyboardButton("🔇 AllTalk خاموش",
                                 callback_data="qcmd|sv_alltalk 0")],
            [InlineKeyboardButton("🪐 جاذبه 200",
                                 callback_data="qcmd|sv_gravity 200"),
             InlineKeyboardButton("🌍 جاذبه 800",
                                 callback_data="qcmd|sv_gravity 800")],
            [InlineKeyboardButton("◀️ منو", callback_data="menu")],
        ]
        # whitelist check on press too (defense in depth)
        await q.edit_message_text("⚡ <b>دستورات سریع:</b>",
                                  parse_mode=ParseMode.HTML,
                                  reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("qcmd|"):
        cmd = data.split("|", 1)[1]
        allowed = {"mp_restartgame 1", "mp_startmoney 16000",
                   "sv_alltalk 1", "sv_alltalk 0",
                   "sv_gravity 200", "sv_gravity 800"}
        if cmd not in allowed:
            await q.answer("❌ دستور مجاز نیست.", show_alert=True)
            return ConversationHandler.END
        ok, out = await safe_rcon(cmd)
        await q.answer("✅ اجرا شد." if ok and not cmd_failed(out)
                       else f"❌ نشد: {out[:100]}", show_alert=True)
        return ConversationHandler.END

    # ---- broadcast / rcon ----------------------------------------
    if data == "act_broadcast":
        await q.edit_message_text("📢 متن پیام رو بفرست:",
                                  reply_markup=back_btn())
        return ASK_SAY

    if data == "act_rcon":
        await q.edit_message_text(
            "⌨️ دستور RCON رو بفرست:", reply_markup=back_btn())
        return ASK_RCON

    # ---- power (safe: argv list, no shell) ------------------------
    if data.startswith("pwr_"):
        action = data.split("_", 1)[1]
        if action not in ("start", "restart", "stop"):
            return ConversationHandler.END
        set_manual_stop(action == "stop")  # persistent: survives bot restart
        res = await systemctl(action)
        if res.startswith("✅"):
            audit.log_event({"start": "🟢 روشن‌کردن سرور بازی",
                             "restart": "🟡 ری‌استارت سرور بازی",
                             "stop": "🔴 خاموش‌کردن سرور بازی"}.get(
                                 action, f"پاور سرور: {action}"))
        text = await render_dashboard()
        await q.edit_message_text(f"{res}\n\n{text}",
                                  parse_mode=ParseMode.HTML,
                                  reply_markup=kb_main(q.from_user.id))
        return ConversationHandler.END

    # ---- mkadm confirm (game admin add/remove) ----------------
    if data.startswith("mkadm|"):
        _, nonce, choice = data.split("|", 2)
        pending = context.user_data.pop("pending_gadm", None)
        if not pending or pending.get("nonce") != nonce:
            await q.answer("⚠️ این تأیید منقضی شده.", show_alert=True)
            return ConversationHandler.END
        if choice != "yes":
            await q.answer("لغو شد.")
            await q.edit_message_text("لغو شد.", reply_markup=back_btn())
            return ConversationHandler.END
        if pending["kind"] == "add":
            res = await add_game_admin(pending["name"], pending["pw"])
            await q.answer(res, show_alert=True)
            await q.edit_message_text(
                f"{res}\n\n👑 <b>{esc(pending['name'])}</b>\n"
                f"🔑 پسورد: <code>{esc(pending['pw'])}</code>\n"
                "بهش بده و بگو یه بار تو کنسول بازی بزنه:\n"
                f"<code>setinfo _password {esc(pending['pw'])}</code>",
                parse_mode=ParseMode.HTML, reply_markup=back_btn())
        else:
            res = await remove_game_admin(pending["name"])
            await q.answer(res, show_alert=True)
            await q.edit_message_text(res, reply_markup=back_btn())
        return ConversationHandler.END

    # ---- modes --------------------------------------------------
    if data == "nav_modes":
        text, kb = await render_modes()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    if data.startswith("mode|"):
        key = data.split("|", 1)[1]
        names = dict(MODE_KEYS)
        if key not in names:
            await q.answer("❌ مود نامعتبر.", show_alert=True)
            return ConversationHandler.END
        ok, out = await safe_rcon(f"sm_botmode {key}")
        if ok and "BOTMODE_SET" in out:
            await q.answer(f"🎮 مود فعال شد: {names[key]}",
                           show_alert=True)
            text, kb = await render_modes()
            try:
                await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                          reply_markup=kb)
            except Exception:
                pass
        else:
            await q.answer(f"❌ نشد: {out[:110]}", show_alert=True)
        return ConversationHandler.END

    if data == "gnight":
        kb = [[InlineKeyboardButton("✅ آره، شروع کن",
                                    callback_data="gnight_yes"),
               InlineKeyboardButton("❌ لغو", callback_data="nav_modes")]]
        await q.edit_message_text(
            "🌙 <b>شب بازی</b>\nمپ می‌شه de_dust2، مود کلاسیک، "
            "ری‌استارت تمیز. شروع کنم؟",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data == "gnight_yes":
        ok1, _o1 = await safe_rcon("changelevel de_dust2")
        await asyncio.sleep(6)
        ok2, out2 = await safe_rcon("sm_botmode classic")
        await safe_rcon("mp_restartgame 1")
        done = ok1 and ok2 and "BOTMODE_SET" in out2
        await q.answer("🌙 شب بازی شروع شد!" if done
                       else "⚠️ یه مرحله‌ش لنگ موند.", show_alert=True)
        text = await render_dashboard()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb_main(q.from_user.id))
        except Exception:
            pass
        return ConversationHandler.END

    # ---- weekly top ----------------------------------------------
    if data == "nav_top":
        text = await render_top()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=back_btn())
        return ConversationHandler.END

    # ---- announcements -------------------------------------------
    if data == "nav_ads":
        text, kb = render_ads_list()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    if data == "ads_add":
        await q.edit_message_text(
            "📣 متن اعلان جدید رو بفرست (انگلیسی — تو بازی فارسی "
            "به‌هم‌ریخته رندر می‌شه):", reply_markup=back_btn())
        return ASK_ADS_ADD

    if data.startswith("ads_view|"):
        idx = _safe_int(data.split("|", 1)[1])
        entries = parse_ads()
        if idx is None or not (0 <= idx < len(entries)):
            await q.edit_message_text("❌ این اعلان دیگه نیست.",
                                      reply_markup=back_btn())
            return ConversationHandler.END
        e = entries[idx]
        kb = [[InlineKeyboardButton("✏️ ویرایش",
                                    callback_data=f"ads_edit|{idx}"),
               InlineKeyboardButton("🗑 حذف",
                                    callback_data=f"ads_del|{idx}")],
              [InlineKeyboardButton("◀️ لیست", callback_data="nav_ads")]]
        await q.edit_message_text(
            f"📣 <b>اعلان #{idx + 1}</b> (نوع: {esc(e['type'])})\n\n"
            f"<code>{esc(e['text'])}</code>",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("ads_edit|"):
        idx = _safe_int(data.split("|", 1)[1])
        context.user_data["ads_edit_idx"] = idx
        await q.edit_message_text("✏️ متن جدید اعلان رو بفرست:",
                                  reply_markup=back_btn())
        return ASK_ADS_EDIT

    if data.startswith("ads_del|"):
        idx = _safe_int(data.split("|", 1)[1])
        if idx is None:
            await q.answer("❌ داده قدیمی/نامعتبر؛ دوباره بازش کن.",
                           show_alert=True)
            return ConversationHandler.END
        kb = [[InlineKeyboardButton("✅ بله، پاکش کن",
                                    callback_data=f"ads_delyes|{idx}"),
               InlineKeyboardButton("❌ لغو", callback_data="nav_ads")]]
        await q.edit_message_text("🗑 این اعلان پاک بشه؟",
                                  reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("ads_delyes|"):
        idx = _safe_int(data.split("|", 1)[1])
        entries = parse_ads()
        if idx is not None and 0 <= idx < len(entries):
            del entries[idx]
            write_ads(entries)
            await safe_rcon("sm plugins reload advertisements")
            await q.answer("🗑 پاک شد.", show_alert=True)
        else:
            await q.answer("❌ اعلان پیدا نشد.", show_alert=True)
        text, kb = render_ads_list()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb)
        except Exception:
            pass
        return ConversationHandler.END

    # ---- telegram admins (owner only) -----------------------------
    if data == "nav_tadm":
        if not is_owner(q.from_user.id):
            await q.edit_message_text("⛔ این بخش فقط برای مالک باته.",
                                      reply_markup=back_btn())
            return ConversationHandler.END
        text, kb = render_tadm()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    if data == "tadm_add":
        if not is_owner(q.from_user.id):
            return ConversationHandler.END
        await q.edit_message_text(
            "👥 آیدی عددی تلگرام طرف رو بفرست (مثلاً 123456789):",
            reply_markup=back_btn())
        return ASK_TADM

    if data.startswith("tadm_del|"):
        if not is_owner(q.from_user.id):
            return ConversationHandler.END
        uid = data.split("|", 1)[1]
        kb = [[InlineKeyboardButton(
            "✅ بله، حذفش کن", callback_data=f"tadm_delyes|{uid}"),
            InlineKeyboardButton("❌ لغو", callback_data="nav_tadm")]]
        await q.edit_message_text(
            f"👥 ادمین <code>{esc(uid)}</code> از بات حذف بشه؟",
            parse_mode=ParseMode.HTML,
            reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END

    if data.startswith("tadm_delyes|"):
        if not is_owner(q.from_user.id):
            await q.answer("⛔ فقط مالک.", show_alert=True)
            return ConversationHandler.END
        try:
            uid = int(data.split("|", 1)[1])
        except ValueError:
            uid = None
        if uid is not None and uid in BOT_ADMINS:
            BOT_ADMINS.discard(uid)
            save_bot_admins()
            await q.answer("✅ حذف شد.", show_alert=True)
        else:
            await q.answer("❌ تو لیست نبود.", show_alert=True)
        text, kb = render_tadm()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb)
        except Exception:
            pass
        return ConversationHandler.END

    # ---- automation ----------------------------------------------
    if data == "nav_auto":
        text, kb = render_auto()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=kb)
        return ConversationHandler.END

    if data.startswith("auto|"):
        which = data.split("|", 1)[1]
        if which == "notifier":
            BOT_STATE["notifier"] = not BOT_STATE.get("notifier", True)
            save_bot_state()
            await q.answer("🔔 خبرچین ورود: "
                           + ("روشن" if BOT_STATE["notifier"] else "خاموش"),
                           show_alert=True)
        elif which == "bridge":
            BOT_STATE["bridge"] = not BOT_STATE.get("bridge", False)
            save_bot_state()
            if BOT_STATE["bridge"]:
                await safe_rcon("log on")
            await q.answer("🎮 پل چت: "
                           + ("روشن" if BOT_STATE["bridge"] else "خاموش"),
                           show_alert=True)
        elif which == "card":
            if BOT_STATE.get("card_msg"):
                BOT_STATE["card_chat"] = 0
                BOT_STATE["card_msg"] = 0
                save_bot_state()
                await q.answer("📡 کارت وضعیت: خاموش", show_alert=True)
            else:
                await q.answer("📡 کارت وضعیت: روشن", show_alert=True)
                msg = await context.bot.send_message(
                    q.message.chat_id, await render_card_text(),
                    parse_mode=ParseMode.HTML)
                BOT_STATE["card_chat"] = q.message.chat_id
                BOT_STATE["card_msg"] = msg.message_id
                save_bot_state()
        text, kb = render_auto()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb)
        except Exception:
            pass
        return ConversationHandler.END

    if data == "nav_resources":
        text = await server_resources()
        await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                  reply_markup=back_btn())
        return ConversationHandler.END

    return ConversationHandler.END


# ---------------------------------------------------------------- VIP helpers

def read_admins_tail(n=10):
    try:
        with open(config.ADMINS_FILE, encoding="utf-8",
                  errors="ignore") as f:
            lines = [l.strip() for l in f
                     if l.strip() and not l.strip().startswith("//")]
        return "\n".join(lines[-n:]) or "(خالی)"
    except OSError:
        return "(فایل پیدا نشد)"


async def add_vip(identity, flags, comment):
    """Append to admins_simple.ini and reload admins. Returns message."""
    try:
        def _write():
            os.makedirs(os.path.dirname(config.ADMINS_FILE), exist_ok=True)
            try:
                with open(config.ADMINS_FILE, encoding="utf-8",
                          errors="ignore") as f:
                    for line in f:
                        s = line.strip()
                        if s and not s.startswith("//"):
                            m = re.match(r'"([^"]*)"', s)
                            if m and m.group(1) == identity:
                                return False  # already registered
            except OSError:
                pass
            with open(config.ADMINS_FILE, "a", encoding="utf-8") as f:
                f.write(f'\n"{identity}" "{flags}" // {comment}\n')
            return True
        if not await asyncio.to_thread(_write):
            return f"ℹ️ ({flags}) برای {identity} از قبل ثبت شده بود."
        ok, out = await safe_rcon("sm_reloadadmins")
        if ok and not cmd_failed(out):
            return f"✅ VIP ({flags}) برای {identity} ثبت شد."
        return f"⚠️ در فایل ثبت شد ولی ریلود نشد: {out[:100]}"
    except Exception as e:  # noqa: BLE001
        return f"❌ خطا: {e}"


def get_installed_maps():
    try:
        maps = [f[:-4] for f in os.listdir(config.MAPS_DIR)
                if f.endswith(".bsp")]
        return sorted(maps) or config.MAPS
    except OSError:
        return config.MAPS


async def systemctl(action):
    """systemctl without shell injection: argv list only."""
    proc = await asyncio.create_subprocess_exec(
        "systemctl", action, config.SERVICE_NAME,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE)
    _, err = await proc.communicate()
    if proc.returncode == 0:
        return f"✅ سرویس {action} شد."
    return f"❌ خطا:\n<code>{esc(err.decode().strip()[:300])}</code>"


async def server_resources():
    stats = await get_process_stats()
    if not stats:
        return ("🖥️ <b>منابع</b>\n"
                "نیاز به <code>pip install psutil</code> دارد.")
    return (f"🖥️ <b>منابع سرور</b>\n\n"
            f"🎮 بازی: CPU {stats['srcds_cpu']:.0f}% | "
            f"RAM {stats['srcds_ram']:.0f}M\n"
            f"🖥️ سیستم: CPU {stats['sys_cpu']:.0f}% | "
            f"RAM {stats['sys_ram']:.0f}%")


# ---------------------------------------------------------------- conversations

async def on_say_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    text = (update.message.text.strip().replace('"', "")
          .replace("\n", " ").replace("\r", " "))
    # try SourceMod first, fall back to engine say if basechat is missing
    ok1, out1 = await safe_rcon(f'sm_csay "{text}"')
    if ok1 and not cmd_failed(out1):
        await update.message.reply_text("📢 پیام پخش شد (وسط صفحه).",
                                        reply_markup=kb_main(update.effective_user.id))
        return ConversationHandler.END
    ok2, out2 = await safe_rcon(f'sm_say "[ADMIN]: {text}"')
    if ok2 and not cmd_failed(out2):
        await update.message.reply_text("📢 پیام پخش شد (چت).",
                                        reply_markup=kb_main(update.effective_user.id))
        return ConversationHandler.END
    ok3, out3 = await safe_rcon(f'say "[ADMIN]: {text}"')
    if ok3 and not cmd_failed(out3):
        await update.message.reply_text("📢 پیام پخش شد (موتور).",
                                        reply_markup=kb_main(update.effective_user.id))
    else:
        detail = out3[:200] if ok3 else out3
        await update.message.reply_text(
            f"❌ پخش نشد:\n<code>{esc(detail)}</code>",
            parse_mode=ParseMode.HTML, reply_markup=kb_main(update.effective_user.id))
    return ConversationHandler.END


async def on_rcon_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    cmd = update.message.text.strip()
    if cmd.lower() in ("/cancel", "انصراف"):
        await update.message.reply_text("لغو شد.",
                                        reply_markup=kb_main(update.effective_user.id))
        return ConversationHandler.END
    ok, out = await safe_rcon(cmd)
    if not ok:
        await update.message.reply_text(out, reply_markup=kb_main(update.effective_user.id))
    else:
        body = esc(out.strip() or "(بدون خروجی)")[:3500]
        await update.message.reply_text(f"<code>{body}</code>",
                                        parse_mode=ParseMode.HTML,
                                        reply_markup=kb_main(update.effective_user.id))
    return ConversationHandler.END


async def on_ban_time(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    uid = context.user_data.get("ban_uid")
    try:
        minutes = int(update.message.text.strip())
    except ValueError:
        await update.message.reply_text("عدد بفرست!")
        return ASK_BAN_TIME
    if minutes < 0:
        await update.message.reply_text("عدد منفی نه! 😄 (0 = دائمی)")
        return ASK_BAN_TIME
    ok, out = await safe_rcon(f"sm_ban #{uid} {minutes} \"Banned by admin\"")
    if not ok or cmd_failed(out):
        msg = out if not ok else f"❌ بن نشد:\n<code>{esc(out[:300])}</code>"
        await update.message.reply_text(msg, parse_mode=ParseMode.HTML,
                                        reply_markup=kb_main(update.effective_user.id))
        return ConversationHandler.END
    dur = "دائمی" if minutes == 0 else f"{minutes} دقیقه"
    await update.message.reply_text(f"🔨 بن شد ({dur}).",
                                    reply_markup=kb_main(update.effective_user.id))
    return ConversationHandler.END


async def on_vip_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    raw = update.message.text.strip().split()[0]
    ok_id, identity = valid_identity(raw)
    if not ok_id:
        await update.message.reply_text(
            "❌ شناسه اشتباهه. قبول می‌کنم:\n"
            "• SteamID مثل <code>STEAM_0:1:123456</code>\n"
            "• IP مثل <code>1.2.3.4</code> (خودکار ! اضافه می‌شه)\n"
            "⚠️ <code>STEAM_ID_LAN</code> / <code>STEAM_ID_PENDING</code> "
            "قبول نیست (شناسه‌ی مشترک چند بازیکنه — خطر امنیتی)",
            parse_mode=ParseMode.HTML)
        return ASK_VIP
    flag = context.user_data.get("vip_flag", "o")
    # SECURITY: IP-based grants are risky (dynamic/shared IPs, CGNAT).
    # - flag z (root) + IP: HIGH risk -> alarming confirmation
    # - flag o (VIP)  + IP: MEDIUM risk -> informative confirmation
    # SteamID grants need no confirmation (unique per player).
    # A nonce ties the buttons to THIS pending (stale "yes" can't
    # confirm a newer pending).
    if identity.startswith("!"):
        vid = uuid.uuid4().hex[:8]
        context.user_data["pending_vip"] = {
            "vid": vid, "identity": identity, "flag": flag}
        if flag == "z":
            warn = (f"⚠️ <b>هشدار امنیتی جدی</b>\n\n"
                    f"داری به IP <code>{esc(identity)}</code> دسترسی "
                    f"<b>root (z)</b> می‌دی!\n\n"
                    f"IP توی ایران اغلب <b>پویا یا مشترک (CGNAT)</b> هست؛ "
                    f"اگه IP عوض بشه یا مشترک باشه، شخص دیگه‌ای root می‌گیره.\n\n"
                    f"مطمئنی؟")
        else:
            warn = (f"⚠️ <b>توجه</b>\n\n"
                    f"داری به IP <code>{esc(identity)}</code> دسترسی "
                    f"<b>VIP (o)</b> می‌دی.\n\n"
                    f"اگه این IP مشترک (CGNAT) باشه، همه‌ی کسایی که پشتش هستن "
                    f"VIP می‌گیرن. مطمئنی؟")
        kb = [[InlineKeyboardButton("✅ بله، مطمئنم",
                                    callback_data=f"vipconfirm|{vid}|yes"),
               InlineKeyboardButton("❌ لغو",
                                    callback_data=f"vipconfirm|{vid}|no")]]
        await update.message.reply_text(warn, parse_mode=ParseMode.HTML,
                                        reply_markup=InlineKeyboardMarkup(kb))
        return ConversationHandler.END
    res = await add_vip(identity, flag, "Added via Telegram")
    await update.message.reply_text(res, reply_markup=kb_main(update.effective_user.id))
    return ConversationHandler.END


async def on_tadm_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update.effective_user.id):
        await update.message.reply_text("⛔ فقط مالک بات.")
        return ConversationHandler.END
    raw = update.message.text.strip()
    if not raw.isdigit():
        await update.message.reply_text("❌ آیدی باید فقط عدد باشه، "
                                        "دوباره بفرست:")
        return ASK_TADM
    uid = int(raw)
    if uid == OWNER_ID:
        await update.message.reply_text("😄 این آیدی خودته!")
        return ConversationHandler.END
    if uid in BOT_ADMINS:
        await update.message.reply_text("ℹ️ این آیدی از قبل ادمین بات هست.")
        return ConversationHandler.END
    BOT_ADMINS.add(uid)
    save_bot_admins()
    text, kb = render_tadm()
    await update.message.reply_text(
        f"✅ <code>{uid}</code> ادمین بات شد.\n\n{text}",
        parse_mode=ParseMode.HTML, reply_markup=kb)
    return ConversationHandler.END


async def on_ads_add_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    text = clean_ad_text(update.message.text)
    if len(text) < 3:
        await update.message.reply_text("❌ متن خیلی کوتاهه، دوباره بفرست:")
        return ASK_ADS_ADD
    entries = parse_ads()
    entries.append({"type": "C", "text": text})
    write_ads(entries)
    await safe_rcon("sm plugins reload advertisements")
    t, kb = render_ads_list()
    await update.message.reply_text(f"✅ اعلان اضافه شد.\n\n{t}",
                                    parse_mode=ParseMode.HTML,
                                    reply_markup=kb)
    return ConversationHandler.END


async def on_ads_edit_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    idx = context.user_data.get("ads_edit_idx")
    text = clean_ad_text(update.message.text)
    entries = parse_ads()
    if idx is None or not (0 <= idx < len(entries)) or len(text) < 3:
        await update.message.reply_text("❌ نشد — اعلان یا متن مشکل داره.",
                                        reply_markup=back_btn())
        return ConversationHandler.END
    entries[idx]["text"] = text
    write_ads(entries)
    await safe_rcon("sm plugins reload advertisements")
    t, kb = render_ads_list()
    await update.message.reply_text(f"✅ ویرایش شد.\n\n{t}",
                                    parse_mode=ParseMode.HTML,
                                    reply_markup=kb)
    return ConversationHandler.END


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("لغو شد.", reply_markup=kb_main(update.effective_user.id))
    return ConversationHandler.END


# ---------------------------------------------------------------- v2 helpers

MODE_KEYS = [
    ("classic", "🕹 کلاسیک"),
    ("match", "🏆 مسابقه"),
    ("headshot", "🎯 هدشات"),
    ("knife", "🔪 چاقو + نارنجک"),
    ("pistol", "🔫 پیستول"),
    ("awp", "🎯 AWP"),
    ("scoutz", "🪂 اسکوت‌نایوز"),
]

ADS_FILE = os.path.join(config.CSTRIKE_DIR,
                        "addons/sourcemod/configs/advertisements.txt")
_ADS_RE = re.compile(
    r'"\d+"\s*\{\s*"type"\s*"([^"]*)"\s*"text"\s*"((?:[^"\\]|\\.)*)"'
    r"\s*\}", re.S)
_ADS_HEADER = (
    '// Advertisements config for SourceMod "Advertisements" plugin\n'
    "// Colors: {DEFAULT} {GREEN} {LIGHTGREEN} {RED} {ORANGE} {BLUE} "
    "{OLIVE}\n\n")


def parse_ads():
    try:
        with open(ADS_FILE, encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except OSError:
        return []
    return [{"type": m.group(1), "text": m.group(2).replace('\\"', '"')}
            for m in _ADS_RE.finditer(content)]


def write_ads(entries):
    def _w():
        if os.path.exists(ADS_FILE):
            import shutil
            shutil.copyfile(ADS_FILE, ADS_FILE + f".bak-{int(time.time())}")
        parts = [_ADS_HEADER, '"Advertisements"\n{\n']
        for i, e in enumerate(entries, 1):
            txt = (e["text"].replace("\\", "").replace('"', "'"))
            parts.append(f'    "{i}"\n    {{\n        "type"      '
                         f'"{e["type"]}"\n        "text"      "{txt}"\n'
                         "    }\n")
        parts.append("}\n")
        with open(ADS_FILE, "w", encoding="utf-8") as f:
            f.write("".join(parts))
    return _w()


def clean_ad_text(text):
    t = str(text).replace('"', "'").replace("\n", " ")
    return re.sub(r"\s+", " ", t).strip()[:200]


def render_ads_list():
    entries = parse_ads()
    if not entries:
        text = "📣 <b>اعلان‌های چرخان بازی</b>\n\n(خالیه)"
        kb = [[InlineKeyboardButton("➕ اعلان جدید",
                                     callback_data="ads_add")],
              [InlineKeyboardButton("◀️ منو", callback_data="menu")]]
        return text, InlineKeyboardMarkup(kb)
    kb = []
    for i, e in enumerate(entries):
        short = e["text"]
        if len(short) > 30:
            short = short[:30] + "…"
        kb.append([InlineKeyboardButton(f"{i + 1}. {short}",
                                        callback_data=f"ads_view|{i}")])
    kb.append([InlineKeyboardButton("➕ اعلان جدید",
                                    callback_data="ads_add"),
               InlineKeyboardButton("◀️ منو", callback_data="menu")])
    return (f"📣 <b>اعلان‌های چرخان بازی</b> ({len(entries)}) — "
            "یکی رو انتخاب کن:"), InlineKeyboardMarkup(kb)


async def render_modes():
    ok, out = await safe_rcon("sm_botmode")
    cur = "نامشخص"
    if ok:
        m = re.search(r"BOTMODE \d+ (.+)", out or "")
        if m:
            cur = m.group(1).strip()
    kb = [[InlineKeyboardButton(label, callback_data=f"mode|{key}")]
          for key, label in MODE_KEYS]
    kb.append([InlineKeyboardButton("🌙 شب بازی (داست۲ + کلاسیک)",
                                    callback_data="gnight")])
    kb.append([InlineKeyboardButton("◀️ منو", callback_data="menu")])
    return (f"🎮 <b>مود بازی</b>\nمود فعلی: <code>{esc(cur)}</code>",
            InlineKeyboardMarkup(kb))


def read_top_players(limit=10):
    db = os.path.join(
        config.CSTRIKE_DIR,
        "addons/sourcemod/data/sqlite/sourcemod-local.sq3")
    if not os.path.exists(db):
        return []
    try:
        con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        try:
            rows = con.execute(
                "SELECT name, points, kills, deaths, headshots FROM ranks "
                "ORDER BY points DESC LIMIT ?", (limit,)).fetchall()
        finally:
            con.close()
        return rows
    except Exception:
        return []


async def render_top():
    rows = await asyncio.to_thread(read_top_players)
    if not rows:
        return "🏆 <b>برترین‌های سرور</b>\n\nهنوز آماری ثبت نشده."
    medals = ["🥇", "🥈", "🥉"]
    lines = ["🏆 <b>برترین‌های سرور</b>\n"]
    for i, (name, pts, kills, deaths, hs) in enumerate(rows):
        mark = medals[i] if i < 3 else "•"
        lines.append(
            f"{mark} <b>{esc(name)}</b> — {pts} امتیاز | "
            f"🎯 {kills} کیل | 💀 {deaths} مرگ | 🤯 {hs} هدشات")
    return "\n".join(lines)


def render_tadm():
    kb = []
    lines = ["👥 <b>ادمین‌های تلگرام بات</b>\n",
             f"👑 مالک: <code>{OWNER_ID}</code>\n"]
    if BOT_ADMINS:
        for uid in sorted(BOT_ADMINS):
            lines.append(f"• <code>{uid}</code>")
            kb.append([InlineKeyboardButton(
                f"🗑 حذف {uid}", callback_data=f"tadm_del|{uid}")])
    else:
        lines.append("(ادمین دیگه‌ای ثبت نشده)")
    kb.append([InlineKeyboardButton("➕ افزودن ادمین",
                                    callback_data="tadm_add"),
               InlineKeyboardButton("◀️ منو", callback_data="menu")])
    return "\n".join(lines), InlineKeyboardMarkup(kb)


def render_auto():
    def st(v):
        return "🟢 روشن" if v else "🔴 خاموش"
    kb = [
        [InlineKeyboardButton(
            f"🔔 خبرچین ورود: {st(BOT_STATE.get('notifier', True))}",
            callback_data="auto|notifier")],
        [InlineKeyboardButton(
            f"🎮 پل چت بازی↔تلگرام: {st(BOT_STATE.get('bridge', False))}",
            callback_data="auto|bridge")],
        [InlineKeyboardButton(
            f"📡 کارت وضعیت زنده: {st(bool(BOT_STATE.get('card_msg')))}",
            callback_data="auto|card")],
        [InlineKeyboardButton("◀️ منو", callback_data="menu")],
    ]
    text = ("🤖 <b>اتوماسیون</b>\n\n"
            "• خبرچین: ورود/خروج بازیکن‌ها رو خبر می‌ده\n"
            "• پل چت: چت بازی میاد اینجا؛ متن ساده‌ای که اینجا بفرستی "
            "می‌ره تو چت بازی\n"
            "• کارت وضعیت: یه پیام زنده که خودش آپدیت می‌شه")
    return text, InlineKeyboardMarkup(kb)


# ------------------------------------------------------ game admin file ops

def _game_admin_names():
    names = set()
    try:
        with open(config.ADMINS_FILE, encoding="utf-8",
                  errors="ignore") as f:
            for line in f:
                s = line.strip()
                if not s or s.startswith("//"):
                    continue
                m = re.match(r'"([^"]*)"', s)
                if m:
                    names.add(m.group(1))
    except OSError:
        pass
    return names


def _clean_pname(name):
    return re.sub(r'["\n\r]', "", str(name)).strip()


async def add_game_admin(name, pw):
    name = _clean_pname(name)
    if len(name) < 2:
        return "❌ اسم بازیکن قابل ثبت نیست."

    def _w():
        import shutil
        try:
            with open(config.ADMINS_FILE, encoding="utf-8",
                      errors="ignore") as f:
                lines = f.readlines()
            shutil.copyfile(config.ADMINS_FILE,
                            config.ADMINS_FILE + f".bak-{int(time.time())}")
        except OSError:
            lines = []
        kept = []
        for line in lines:
            s = line.strip()
            m = (re.match(r'"([^"]*)"', s)
                 if s and not s.startswith("//") else None)
            if m and m.group(1) == name:
                continue  # upsert: exactly one entry per admin name
            kept.append(line)
        kept.append(f'\n"{name}" "99:z" "{pw}" // Game admin via bot\n')
        with open(config.ADMINS_FILE, "w", encoding="utf-8") as f:
            f.writelines(kept)
    await asyncio.to_thread(_w)
    ok, out = await safe_rcon("sm_reloadadmins")
    if ok and not cmd_failed(out):
        return f"✅ {name} ادمین بازی شد."
    return "⚠️ تو فایل ثبت شد ولی ریلود نشد."


async def remove_game_admin(name):
    name = _clean_pname(name)

    def _w():
        import shutil
        with open(config.ADMINS_FILE, encoding="utf-8",
                  errors="ignore") as f:
            lines = f.readlines()
        shutil.copyfile(config.ADMINS_FILE,
                        config.ADMINS_FILE + f".bak-{int(time.time())}")
        kept, removed = [], 0
        for line in lines:
            s = line.strip()
            m = (re.match(r'"([^"]*)"', s)
                 if s and not s.startswith("//") else None)
            if m and m.group(1) == name:
                removed += 1
                continue
            kept.append(line)
        with open(config.ADMINS_FILE, "w", encoding="utf-8") as f:
            f.writelines(kept)
        return removed
    removed = await asyncio.to_thread(_w)
    if not removed:
        return "❌ همچین ادمینی تو فایل نیست."
    ok, out = await safe_rcon("sm_reloadadmins")
    return "✅ ادمین بازی حذف و ریلود شد." if ok else "⚠️ حذف شد، ریلود نشد."


# ------------------------------------------------------------ notify helpers

def _admin_targets():
    # Every admin source: owner + json admins + config admins, deduped.
    return [OWNER_ID] + sorted(
        (set(BOT_ADMINS) | set(config.ADMIN_IDS)) - {OWNER_ID})


async def _notify_admins(app, text):
    for aid in _admin_targets():
        try:
            await app.bot.send_message(aid, text, parse_mode=ParseMode.HTML)
        except Exception:
            pass


async def render_card_text():
    ok, out = await safe_rcon("status")
    info = parse_status(out) if ok else None
    sc_ok, sc = await safe_rcon("sm_bot_scores")
    m = re.search(r"BOTSCORES CT=(\d+) T=(\d+)", sc or "")
    score = f"🔵 CT {m.group(1)} — 🔴 T {m.group(2)}" if m else ""
    now = time.strftime("%H:%M")
    if not info:
        return (f"📡 <b>{esc(config.SERVER_NAME)}</b>\n"
                f"🔴 سرور بی‌پاسخ است.\n🕐 {now}")
    humans = [p for p in info["players"] if p.get("steamid") != "BOT"]
    names = "\n".join(f"• {esc(p['name'])}" for p in humans) or "(خالی)"
    return (f"📡 <b>{esc(config.SERVER_NAME)}</b>\n"
            f"🗺 مپ: <code>{esc(info['map'])}</code> | "
            f"👥 بازیکن: <b>{len(humans)}</b>\n"
            f"{score}\n{names}\n🕐 آپدیت: {now}")


# ------------------------------------------------------- background: players

async def players_watcher(app):
    """Join/leave notifier + live status card updater."""
    await asyncio.sleep(15)
    prev = None
    while True:
        try:
            ok, out = await safe_rcon("status")
            if ok:
                info = parse_status(out)
                cur = {p["id"]: p["name"] for p in info["players"]
                       if p.get("steamid") != "BOT"}
                if prev is not None and BOT_STATE.get("notifier", True):
                    for uid_, name in cur.items():
                        if uid_ not in prev:
                            await _notify_admins(
                                app,
                                f"🟢 <b>{esc(name)}</b> اومد تو سرور — "
                                f"الان {len(cur)} نفر آنلاینن")
                    for uid_, name in prev.items():
                        if uid_ not in cur:
                            await _notify_admins(
                                app,
                                f"🔴 <b>{esc(name)}</b> از سرور رفت — "
                                f"الان {len(cur)} نفر آنلاینن")
                prev = cur
                if BOT_STATE.get("card_msg"):
                    try:
                        await app.bot.edit_message_text(
                            chat_id=BOT_STATE["card_chat"],
                            message_id=BOT_STATE["card_msg"],
                            text=await render_card_text(),
                            parse_mode=ParseMode.HTML)
                    except Exception:
                        pass
        except Exception:
            log.exception("players_watcher error")
        await asyncio.sleep(20)


# ---------------------------------------------------------- background: chat

_SAY_RE = re.compile(
    r'^L \d{2}/\d{2}/\d{4} - \d{2}:\d{2}:\d{2}: '
    r'"(.+?)<\d+><[^>]*><[^>]*>" (say|say_team) "(.*)"\s*$')


async def bridge_tail(app):
    """Tail the newest server log; forward in-game chat to bot admins."""
    path, offset = None, 0
    while True:
        await asyncio.sleep(4)
        if not BOT_STATE.get("bridge"):
            continue
        try:
            logs_dir = os.path.join(config.CSTRIKE_DIR, "logs")
            files = glob.glob(os.path.join(logs_dir, "*.log"))
            if not files:
                continue
            newest = max(files, key=os.path.getmtime)
            size = os.path.getsize(newest)
            if newest != path:
                path, offset = newest, size
                continue
            if size < offset:
                offset = 0
            if size == offset:
                continue
            def _read():
                with open(path, encoding="utf-8", errors="ignore") as f:
                    f.seek(offset)
                    return f.read(), f.tell()
            chunk, offset = await asyncio.to_thread(_read)
            for line in chunk.splitlines():
                m = _SAY_RE.match(line.strip())
                if not m:
                    continue
                name, kind, text = m.group(1), m.group(2), m.group(3)
                if name == "Console" or not text.strip():
                    continue
                tag = " (تیمی)" if kind == "say_team" else ""
                await _notify_admins(
                    app, f"🎮 <b>{esc(name)}</b>{tag}: {esc(text)}")
        except Exception:
            log.exception("bridge_tail error")


async def on_bridge_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Plain admin text -> game chat, while the bridge is on."""
    if not BOT_STATE.get("bridge"):
        return
    if not is_admin(update.effective_user.id):
        return
    msg = update.message or update.edited_message
    if not msg or not msg.text:
        return
    text = (msg.text.strip().replace('"', "")
          .replace("\n", " ").replace("\r", " "))
    if not text:
        return
    ok, out = await safe_rcon(f'sm_say "[TG] {text[:120]}"')
    if ok and not cmd_failed(out):
        await msg.reply_text("🎮 رفت تو چت بازی")
    else:
        await msg.reply_text("❌ نرفت — سرور جواب نداد.")


# ---------------------------------------------------------------- watchdog

async def watchdog(app):
    """Restart crashed srcds every 45s. Respects persistent manual stops,
    warns once if psutil is missing, checks restart success, and avoids
    alert spam in a crash loop (alerts on 1st, then every 10th)."""
    await asyncio.sleep(10)
    warned_no_psutil = False
    crash_streak = 0
    while True:
        await asyncio.sleep(45)
        try:
            if is_manual_stop():
                crash_streak = 0
                continue
            stats = await get_process_stats()
            if stats is None:
                if not warned_no_psutil:
                    log.warning("watchdog idle: psutil not installed; "
                                "install it for auto-heal")
                    warned_no_psutil = True
                continue
            if stats["running"]:
                crash_streak = 0
                continue
            crash_streak += 1
            res = await systemctl("restart")
            restarted_ok = "✅" in res
            if crash_streak == 1 or crash_streak % 10 == 0:
                for aid in _admin_targets():
                    try:
                        await app.bot.send_message(
                            aid,
                            f"🚨 <b>Watchdog:</b> سرور کرش کرده بود؛ "
                            f"ری‌استارت "
                            f"{'موفق شد 🟢' if restarted_ok else 'ناموفق بود 🔴'}"
                            f" (تلاش #{crash_streak})",
                            parse_mode=ParseMode.HTML)
                    except Exception:
                        pass
            if not restarted_ok:
                log.error("watchdog restart failed: %s", res[:200])
        except Exception:
            log.exception("watchdog error")


# ---------------------------------------------------------------- main

def main():
    app = ApplicationBuilder().token(config.BOT_TOKEN).build()

    conv = ConversationHandler(
        entry_points=[CallbackQueryHandler(on_button)],
        states={
            ASK_SAY: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                     on_say_text)],
            ASK_RCON: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                      on_rcon_text)],
            ASK_BAN_TIME: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                          on_ban_time)],
            ASK_VIP: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                     on_vip_text)],
            ASK_TADM: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                      on_tadm_text)],
            ASK_ADS_ADD: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                         on_ads_add_text)],
            ASK_ADS_EDIT: [MessageHandler(filters.TEXT & ~filters.COMMAND,
                                          on_ads_edit_text)],
        },
        fallbacks=[CommandHandler("cancel", cancel),
                   CallbackQueryHandler(on_button)],
        per_message=False,
    )
    app.add_handler(CommandHandler("start", start))
    app.add_handler(conv)
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND,
                                   on_bridge_text))

    async def _post_init(app):
        # Telegram command menu (Ali's order 2026-10-23): commands appear
        # in the chat's / menu so /start never has to be typed by hand.
        try:
            await app.bot.set_my_commands([
                BotCommand("start", "🎮 منوی اصلی مدیریت سرور"),
                BotCommand("cancel", "❌ لغو عملیات جاری"),
            ])
            log.info("Telegram command menu registered.")
        except Exception:
            log.exception("set_my_commands failed")
        asyncio.create_task(watchdog(app))
        asyncio.create_task(players_watcher(app))
        asyncio.create_task(bridge_tail(app))

    app.post_init = _post_init
    log.info("Ultimate bot v2 started.")
    app.run_polling()


if __name__ == "__main__":
    main()
