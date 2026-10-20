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
import logging
import os
import re

from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
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

ASK_SAY, ASK_RCON, ASK_BAN_TIME, ASK_VIP = range(4)

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
        return True, await arcon(cmd)
    except RCONAuthError:
        return False, "❌ پسورد RCON اشتباه است."
    except RCONError as e:
        return False, f"❌ خطا در اتصال به سرور: {e}"
    except Exception as e:  # noqa: BLE001
        log.exception("rcon failed")
        return False, f"❌ خطای غیرمنتظره: {e}"


def cmd_failed(output):
    return bool(_ERROR_RE.search(output or ""))


def is_admin(uid):
    return uid in config.ADMIN_IDS


def esc(text):
    """Escape for HTML parse mode (prevents Markdown/HTML breakage)."""
    return (str(text).replace("&", "&amp;")
            .replace("<", "&lt;").replace(">", "&gt;"))


# ---------------------------------------------------------------- keyboards

def kb_main():
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("🔄 بروزرسانی", callback_data="nav_home"),
         InlineKeyboardButton("👥 بازیکن‌ها", callback_data="nav_players")],
        [InlineKeyboardButton("🗺️ تعویض مپ", callback_data="nav_maps"),
         InlineKeyboardButton("🧩 پلاگین‌ها", callback_data="nav_plugins")],
        [InlineKeyboardButton("🌟 VIP / ادمین", callback_data="nav_vips"),
         InlineKeyboardButton("⚡ دستورات سریع", callback_data="nav_quick")],
        [InlineKeyboardButton("📢 پیام همگانی", callback_data="act_broadcast"),
         InlineKeyboardButton("⌨️ کنسول RCON", callback_data="act_rcon")],
        [InlineKeyboardButton("🖥️ منابع", callback_data="nav_resources"),
         InlineKeyboardButton("◀️ منو", callback_data="menu")],
        [InlineKeyboardButton("🟢 Start", callback_data="pwr_start"),
         InlineKeyboardButton("🟡 Restart", callback_data="pwr_restart"),
         InlineKeyboardButton("🔴 Stop", callback_data="pwr_stop")],
    ])


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
        import time
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
    return True


async def guard_msg(update: Update):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("⛔ شما دسترسی ندارید.")
        return False
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
                                    reply_markup=kb_main())


async def on_button(update: Update, context: ContextTypes.DEFAULT_TYPE):
    q = update.callback_query
    # NOTE: exactly ONE q.answer() per callback path (Telegram rejects a 2nd).
    if not await guard(q):
        return ConversationHandler.END
    data = q.data
    # Navigation callbacks get a plain ack here; action callbacks
    # (pact/plg/setmap/qcmd/vipreload) answer themselves with show_alert.
    _action_prefixes = (f"pact{_SEP}", f"setmap{_SEP}", f"plg{_SEP}",
                        "qcmd|", "vipreload")
    if not data.startswith(_action_prefixes):
        try:
            await q.answer()
        except Exception:
            pass

    if data in ("menu", "nav_home"):
        text = await render_dashboard()
        try:
            await q.edit_message_text(text, parse_mode=ParseMode.HTML,
                                      reply_markup=kb_main())
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

    # ---- maps (paginated) ---------------------------------------
    if data == "nav_maps" or data.startswith("mapspage|"):
        page = int(data.split("|", 1)[1]) if "|" in data else 0
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
                                          reply_markup=kb_main())
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
        text = await render_dashboard()
        await q.edit_message_text(f"{res}\n\n{text}",
                                  parse_mode=ParseMode.HTML,
                                  reply_markup=kb_main())
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
            with open(config.ADMINS_FILE, "a", encoding="utf-8") as f:
                f.write(f'\n"{identity}" "{flags}" // {comment}\n')
        await asyncio.to_thread(_write)
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
    text = update.message.text.strip().replace('"', "")
    # try SourceMod first, fall back to engine say if basechat is missing
    ok1, out1 = await safe_rcon(f'sm_csay "{text}"')
    if ok1 and not cmd_failed(out1):
        await update.message.reply_text("📢 پیام پخش شد (وسط صفحه).",
                                        reply_markup=kb_main())
        return ConversationHandler.END
    ok2, out2 = await safe_rcon(f'sm_say "[ADMIN]: {text}"')
    if ok2 and not cmd_failed(out2):
        await update.message.reply_text("📢 پیام پخش شد (چت).",
                                        reply_markup=kb_main())
        return ConversationHandler.END
    ok3, out3 = await safe_rcon(f'say "[ADMIN]: {text}"')
    if ok3 and not cmd_failed(out3):
        await update.message.reply_text("📢 پیام پخش شد (موتور).",
                                        reply_markup=kb_main())
    else:
        detail = out3[:200] if ok3 else out3
        await update.message.reply_text(
            f"❌ پخش نشد:\n<code>{esc(detail)}</code>",
            parse_mode=ParseMode.HTML, reply_markup=kb_main())
    return ConversationHandler.END


async def on_rcon_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not await guard_msg(update):
        return ConversationHandler.END
    cmd = update.message.text.strip()
    if cmd.lower() in ("/cancel", "انصراف"):
        await update.message.reply_text("لغو شد.",
                                        reply_markup=kb_main())
        return ConversationHandler.END
    ok, out = await safe_rcon(cmd)
    if not ok:
        await update.message.reply_text(out, reply_markup=kb_main())
    else:
        body = esc(out.strip() or "(بدون خروجی)")[:3500]
        await update.message.reply_text(f"<code>{body}</code>",
                                        parse_mode=ParseMode.HTML,
                                        reply_markup=kb_main())
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
                                        reply_markup=kb_main())
        return ConversationHandler.END
    dur = "دائمی" if minutes == 0 else f"{minutes} دقیقه"
    await update.message.reply_text(f"🔨 بن شد ({dur}).",
                                    reply_markup=kb_main())
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
        import uuid
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
    await update.message.reply_text(res, reply_markup=kb_main())
    return ConversationHandler.END


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("لغو شد.", reply_markup=kb_main())
    return ConversationHandler.END


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
                for aid in config.ADMIN_IDS:
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
        },
        fallbacks=[CommandHandler("cancel", cancel),
                   CallbackQueryHandler(on_button)],
        per_message=False,
    )
    app.add_handler(CommandHandler("start", start))
    app.add_handler(conv)
    app.add_handler(CallbackQueryHandler(on_button))

    async def _post_init(app):
        asyncio.create_task(watchdog(app))

    app.post_init = _post_init
    log.info("Ultimate bot started.")
    app.run_polling()


if __name__ == "__main__":
    main()
