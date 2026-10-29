# -*- coding: utf-8 -*-
"""Admin action history for the Wh1Tes css-bot.

Collects admin actions from three sources and renders them as one
timeline with Jalali (Shamsi) dates and Tehran time:

  1. Live audit log (audit_log.jsonl next to this file) — every action
     command the bot itself sends over RCON, plus power actions,
     recorded with the Telegram admin who triggered it.
  2. Game server log (cstrike/logs) — RCON commands issued before this
     module existed (actor shown as «ربات/پنل»), deduplicated against 1.
  3. SourceMod logs (addons/sourcemod/logs) — actions admins performed
     in-game via the SM admin menu (kick/ban/slap/slay/csay/...).

Server logs are timestamped in UTC; everything is converted to
Asia/Tehran (fixed UTC+03:30, Iran has no DST anymore) and Jalali.
"""

import contextvars
import glob
import html
import json
import os
import re
import time
from datetime import datetime, timedelta, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
AUDIT_FILE = os.path.join(HERE, "audit_log.jsonl")
GAME_LOG_DIR = "/opt/counter/server/cstrike/logs"
SM_LOG_DIR = "/opt/counter/server/cstrike/addons/sourcemod/logs"

TEHRAN = timezone(timedelta(hours=3, minutes=30))
UTC = timezone.utc

_ACTOR = contextvars.ContextVar("audit_actor", default="")

FA_DIGITS = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")
FA_MONTHS = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
             "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]


def fa_num(text):
    return str(text).translate(FA_DIGITS)


# ------------------------------------------------------------------ Jalali

def gregorian_to_jalali(gy, gm, gd):
    g_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    j_days = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29]
    gy -= 1600
    gm -= 1
    gd -= 1
    g_day_no = 365 * gy + (gy + 3) // 4 - (gy + 99) // 100 + (gy + 399) // 400
    for i in range(gm):
        g_day_no += g_days[i]
    if gm > 1 and ((gy % 4 == 0 and gy % 100 != 0) or (gy + 1600) % 400 == 0):
        g_day_no += 1
    g_day_no += gd
    j_day_no = g_day_no - 79
    j_np = j_day_no // 12053
    j_day_no %= 12053
    jy = 979 + 33 * j_np + 4 * (j_day_no // 1461)
    j_day_no %= 1461
    if j_day_no >= 366:
        jy += (j_day_no - 1) // 365
        j_day_no = (j_day_no - 1) % 365
    jm = 0
    while jm < 11 and j_day_no >= j_days[jm]:
        j_day_no -= j_days[jm]
        jm += 1
    return jy, jm + 1, j_day_no + 1


def fmt_tehran(epoch):
    """epoch (UTC seconds) -> '۱ آبان ۱۴۰۵ — ۲۲:۲۱' in Tehran time."""
    dt = datetime.fromtimestamp(epoch, tz=UTC).astimezone(TEHRAN)
    jy, jm, jd = gregorian_to_jalali(dt.year, dt.month, dt.day)
    return fa_num(f"{jd} {FA_MONTHS[jm - 1]} {jy} — {dt.hour:02d}:{dt.minute:02d}")


# ------------------------------------------------------------------ actors

def set_actor(name, uid=None):
    label = (name or "").strip()
    if uid is not None:
        label = f"{label} ({uid})" if label else str(uid)
    _ACTOR.set(label)


def current_actor():
    return _ACTOR.get()


# ------------------------------------------------------------------ describe

_MODE_NAMES = {
    "classic": "کلاسیک", "match": "مچ", "headshot": "هدشات",
    "knife": "چاقو و نارنجک", "pistol": "پیستول", "pistols": "پیستول", "awp": "AWP",
    "scout": "اسکات‌و‌چاقو", "scoutz": "اسکات‌و‌چاقو", "scoutzknivez": "اسکات‌و‌چاقو",
}


def _plugin_basename(token):
    """'disabled/myplugin.smx' or 'myplugin' -> 'myplugin' (cosmetic only)."""
    name = token.strip().strip('"')
    name = name.rsplit("/", 1)[-1]
    if name.lower().endswith(".smx"):
        name = name[:-4]
    return name or token


def describe(cmd):
    """RCON command string -> short Persian description, or None when
    the command is not an admin *action* (queries/status are skipped)."""
    if not cmd:
        return None
    c = cmd.strip()
    low = c.lower()
    parts = c.split(None, 1)
    head = parts[0].lower() if parts else ""
    rest = parts[1] if len(parts) > 1 else ""

    if head == "sm_csay":
        return f"📢 پیام همگانی: «{rest.strip('\"')[:80]}»"
    if head in ("sm_say", "sm_psay"):
        return f"💬 پیام ادمین: «{rest.strip('\"')[:80]}»"
    if head == "sm_kick":
        return f"👢 کیک بازیکن {rest}".strip()
    if head in ("sm_ban", "sm_banip", "sm_addban"):
        return f"🔨 بن {rest}".strip()
    if head == "sm_unban":
        return f"🔓 آنبن {rest}".strip()
    if head == "sm_slay":
        return f"💀 کشتن (Slay) {rest}".strip()
    if head == "sm_slap":
        return f"👋 سیلی (Slap) {rest}".strip()
    if head in ("sm_silence", "sm_mute", "sm_gag", "sm_ungag", "sm_unmute"):
        return f"🔇 تغییر وضعیت سکوت {rest}".strip()
    if head == "sm_botmode":
        key = rest.strip().strip('"').lower()
        if not key:
            return None  # bare sm_botmode is a status query, not an action
        return f"🎮 تغییر مود بازی به {_MODE_NAMES.get(key, key)}"
    if head == "sm_bot_swap":
        return "🔀 جابه‌جایی بازیکن بین تیم‌ها"
    if head in ("bot_kick", "sm_bot_kick"):
        return f"🤖 کیک بات‌ها {rest}".strip()
    if head == "changelevel":
        return f"🗺️ تعویض مپ به {rest.strip()}"
    if head == "sm" and rest.lower().startswith("plugins load"):
        return f"🧩 فعال‌کردن پلاگین {_plugin_basename(rest.split()[-1])}"
    if head == "sm" and rest.lower().startswith("plugins unload"):
        return f"🧩 غیرفعال‌کردن پلاگین {_plugin_basename(rest.split()[-1])}"
    if head == "sm_reloadadmins":
        return "🌟 بروزرسانی لیست ادمین‌ها و VIP"
    if head == "sm_team":
        return f"🔀 انتقال بازیکن {rest}".strip()
    if low.startswith("sm_execcfg") or head == "exec":
        return f"⚙️ اجرای کانفیگ {rest}".strip()
    return None


# ------------------------------------------------------------------ writing

def log_event(desc, scope="ربات"):
    """Record a non-RCON admin action (e.g. server power) right now."""
    entry = {
        "ts": int(time.time()),
        "actor": current_actor() or "سیستم (خودکار)",
        "scope": scope,
        "desc": desc,
    }
    try:
        with open(AUDIT_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except OSError:
        pass
    return entry


def maybe_log(cmd):
    """Called by the bot after a successful RCON command; records the
    command when it is an admin action."""
    desc = describe(cmd)
    if desc is None:
        return
    entry = {
        "ts": int(time.time()),
        "actor": current_actor() or "سیستم (خودکار)",
        "scope": "ربات",
        "desc": desc,
        "cmd": cmd.strip()[:160],
    }
    try:
        with open(AUDIT_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except OSError:
        pass


# ------------------------------------------------------------------ reading

_TS_RE = re.compile(r"L (\d{2})/(\d{2})/(\d{4}) - (\d{2}):(\d{2}):(\d{2}): (.*)")


def _log_ts_epoch(m):
    mo, dd, yy, hh, mi, ss = (int(m.group(i)) for i in range(1, 7))
    dt = datetime(yy, mo, dd, hh, mi, ss, tzinfo=UTC)
    return int(dt.timestamp())


def _tail_lines(path, max_bytes=600_000):
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            if size > max_bytes:
                f.seek(size - max_bytes)
                f.readline()
            data = f.read()
        return data.decode("utf-8", "replace").splitlines()
    except OSError:
        return []


def _recent_files(directory, pattern, count):
    files = sorted(glob.glob(os.path.join(directory, pattern)),
                   key=lambda p: os.path.getmtime(p) if os.path.exists(p) else 0)
    return files[-count:]


def _audit_entries():
    """Live audit entries, bounded to the same tail window used for the game/SM logs so this stays cheap even if audit_log.jsonl grows large over months. The file on disk is never truncated — this only bounds what a single history render reads."""
    out = []
    for line in _tail_lines(AUDIT_FILE):
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        out.append({
            "ts": int(e.get("ts", 0)),
            "actor": e.get("actor", ""),
            "scope": e.get("scope", "ربات"),
            "desc": e.get("desc", ""),
            "cmd": e.get("cmd", ""),
        })
    return out


_RCON_RE = re.compile(r'rcon from "127\.0\.0\.1:\d+": command "(.*)"$')


def _game_log_entries():
    """Action commands seen as RCON in the game log (pre-audit history)."""
    out = []
    for path in _recent_files(GAME_LOG_DIR, "L*.log", 2):
        for line in _tail_lines(path):
            m = _TS_RE.match(line)
            if not m:
                continue
            r = _RCON_RE.search(m.group(7))
            if not r:
                continue
            cmd = r.group(1).replace('\\"', '"').strip()
            if not cmd:
                continue
            desc = describe(cmd)
            if desc is None:
                continue
            out.append({
                "ts": _log_ts_epoch(m),
                "actor": "ربات/پنل",
                "scope": "ربات",
                "desc": desc,
                "cmd": cmd[:160],
            })
    return out


_SM_PATTERNS = [
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" kicked "([^"]+)<\d+>'),
     lambda a, b: f"👢 {a} بازیکن {b} را کیک کرد"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" banned "([^"]+)<\d+>'),
     lambda a, b: f"🔨 {a} بازیکن {b} را بن کرد"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" slapped "([^"]+)<\d+>'),
     lambda a, b: f"👋 {a} به {b} سیلی زد (Slap)"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" slayed "([^"]+)<\d+>'),
     lambda a, b: f"💀 {a} بازیکن {b} را کشت (Slay)"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" triggered sm_csay \(text "([^"]*)"\)'),
     lambda a, b: f"📢 {a} پیام همگانی داد: «{b[:80]}»"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" triggered sm_say \(text "([^"]*)"\)'),
     lambda a, b: f"💬 {a} پیام ادمین فرستاد: «{b[:80]}»"),
    (re.compile(r'"([^"]+)<\d+><[^>]*><[^>]*>" silenced "([^"]+)<\d+>'),
     lambda a, b: f"🔇 {a} بازیکن {b} را ساکت کرد"),
]


def _sm_log_entries():
    out = []
    for path in _recent_files(SM_LOG_DIR, "L*.log", 3):
        for line in _tail_lines(path):
            m = _TS_RE.match(line)
            if not m:
                continue
            body = m.group(7)
            for regex, build in _SM_PATTERNS:
                hit = regex.search(body)
                if hit:
                    out.append({
                        "ts": _log_ts_epoch(m),
                        "actor": hit.group(1),
                        "scope": "سرور",
                        "desc": build(hit.group(1), hit.group(2)),
                        "cmd": "",
                    })
                    break
    return out


def get_history(limit=15):
    entries = _audit_entries()
    known = {(e["ts"] // 60, e.get("cmd", "")) for e in entries if e.get("cmd")}
    merged = list(entries)
    for e in _game_log_entries():
        if (e["ts"] // 60, e.get("cmd", "")) in known:
            continue  # richer live-audit entry already covers it
        merged.append(e)
    bot_ts = [e["ts"] for e in merged]
    for e in _sm_log_entries():
        if e["actor"] == "Console":
            # SM echoes RCON-issued commands as Console actions — when the
            # same moment already has a bot/RCON entry it is a duplicate.
            if any(abs(e["ts"] - t) <= 60 for t in bot_ts):
                continue
            e["actor"] = "کنسول سرور"
        merged.append(e)
    merged.sort(key=lambda e: e["ts"], reverse=True)
    return merged[:limit]


_SCOPE_ICON = {"ربات": "🤖", "سرور": "🎮"}


def render_history(limit=15):
    entries = get_history(limit)
    if not entries:
        return "📜 <b>سابقه اقدامات ادمین‌ها</b>\n\nهنوز اقدامی ثبت نشده."
    lines = ["📜 <b>سابقه اقدامات ادمین‌ها</b> (جدیدترین اول)\n"]
    for e in entries:
        icon = _SCOPE_ICON.get(e["scope"], "•")
        actor = html.escape(e["actor"] or "نامشخص")
        desc = html.escape(e["desc"])
        lines.append(f"{icon} <b>{actor}</b> — {desc}\n"
                     f"🕒 {fmt_tehran(e['ts'])}")
    return "\n".join(lines)
