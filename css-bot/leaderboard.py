# -*- coding: utf-8 -*-
"""Leaderboard views for the css-bot: reads the game's SQLite rank DB
(sourcemod-local.sq3, written by the Wh1Tes Rank plugin) read-only and
renders the points top-10 plus per-weapon top-5 boards for Telegram."""
import contextlib
import html
import sqlite3

from telegram import InlineKeyboardButton, InlineKeyboardMarkup

DB_PATH = "/opt/counter/server/cstrike/addons/sourcemod/data/sqlite/sourcemod-local.sq3"

_FA = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")

PRETTY = {
    "m4a1": "M4A1", "ak47": "AK-47", "awp": "AWP", "deagle": "Desert Eagle",
    "usp": "USP", "glock": "Glock", "p228": "P228", "fiveseven": "Five-Seven",
    "elite": "Dual Elites", "m3": "M3 Shotgun", "xm1014": "XM1014",
    "mac10": "MAC-10", "tmp": "TMP", "mp5navy": "MP5", "ump45": "UMP45",
    "p90": "P90", "galil": "Galil", "famas": "FAMAS", "sg552": "SG-552",
    "aug": "AUG", "sg550": "SG-550", "g3sg1": "G3SG1", "scout": "Scout",
    "m249": "M249", "knife": "Knife", "hegrenade": "HE Grenade",
}

MEDALS = ["🥇", "🥈", "🥉"]


def fa(x):
    return str(x).translate(_FA)


def pretty(weapon):
    return PRETTY.get(weapon, weapon.upper())


def _db():
    return sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True, timeout=5)


def _top_points(limit=10):
    with contextlib.closing(_db()) as c:
        return c.execute(
            "SELECT name, points, kills, deaths FROM ranks "
            "ORDER BY points DESC, kills DESC LIMIT ?", (limit,)).fetchall()


def _weapon_totals(limit=8):
    with contextlib.closing(_db()) as c:
        return c.execute(
            "SELECT weapon, SUM(kills) AS total FROM weapon_kills "
            "GROUP BY weapon ORDER BY total DESC LIMIT ?", (limit,)).fetchall()


def _weapon_top(weapon, limit=5):
    with contextlib.closing(_db()) as c:
        return c.execute(
            "SELECT name, kills FROM weapon_kills WHERE weapon=? "
            "ORDER BY kills DESC, name ASC LIMIT ?", (weapon, limit)).fetchall()


def _weapon_leader(weapon):
    rows = _weapon_top(weapon, 1)
    return rows[0] if rows else None


def render_main():
    """(text, keyboard) for the main leaderboard message."""
    try:
        points = _top_points(10)
        weapons = _weapon_totals(8)
    except Exception:
        text = "🏆 <b>لیدربورد</b>\n\n⚠️ دیتابیس رنک الان در دسترس نیست."
        kb = InlineKeyboardMarkup([
            [InlineKeyboardButton("◀️ منو", callback_data="menu")]])
        return text, kb

    lines = ["🏆 <b>لیدربورد سرور</b>", "", "👑 <b>تاپ ۱۰ امتیاز</b>"]
    if points:
        for i, (name, pts, kills, deaths) in enumerate(points, 1):
            kd = kills / deaths if deaths else float(kills)
            medal = MEDALS[i - 1] if i <= 3 else f"{fa(i)}."
            lines.append(
                f"{medal} {html.escape(str(name))} — {fa(pts)} امتیاز "
                f"({fa(kills)}/{fa(deaths)} • K/D {fa(f'{kd:.2f}')})")
    else:
        lines.append("هنوز امتیازی ثبت نشده — از امشب شروع می‌شه!")

    lines += ["", "🔫 <b>تاپ اسلحه‌ها</b>"]
    if weapons:
        for weapon, total in weapons[:5]:
            leader = _weapon_leader(weapon)
            lead = (f"🥇 {html.escape(str(leader[0]))} ({fa(leader[1])})"
                    if leader else "—")
            lines.append(
                f"• <b>{html.escape(pretty(weapon))}</b> — مجموع {fa(total)} کیل | {lead}")
    else:
        lines.append("هنوز کیلی با اسلحه ثبت نشده.")

    rows = []
    row = []
    for weapon, _total in weapons:
        row.append(InlineKeyboardButton(
            f"🔫 {pretty(weapon)}", callback_data=f"boardw|{weapon}"))
        if len(row) == 2:
            rows.append(row)
            row = []
    if row:
        rows.append(row)
    rows.append([InlineKeyboardButton("🔄 بروزرسانی", callback_data="nav_board"),
                 InlineKeyboardButton("◀️ منو", callback_data="menu")])
    return "\n".join(lines), InlineKeyboardMarkup(rows)


def render_weapon(weapon):
    """(text, keyboard) for one weapon's top-5 board."""
    title = pretty(weapon)
    try:
        top = _weapon_top(weapon, 5)
    except Exception:
        top = None
    lines = [f"🔫 <b>{html.escape(title)} — تاپ ۵</b>", ""]
    if top:
        for i, (name, kills) in enumerate(top, 1):
            medal = MEDALS[i - 1] if i <= 3 else f"{fa(i)}."
            lines.append(f"{medal} {html.escape(str(name))} — {fa(kills)} کیل")
    elif top is None:
        lines.append("⚠️ دیتابیس رنک الان در دسترس نیست.")
    else:
        lines.append("هنوز کسی با این اسلحه کیل نگرفته.")
    kb = InlineKeyboardMarkup([
        [InlineKeyboardButton("🔙 لیدربورد", callback_data="nav_board")],
        [InlineKeyboardButton("◀️ منو", callback_data="menu")]])
    return "\n".join(lines), kb
