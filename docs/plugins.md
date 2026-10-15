# راهنمای پلاگین‌ها

همه‌ی پلاگین‌های سفارشی این سرور با SourceMod **1.7.3-stable** کامپایل شده‌اند.
سورس‌ها در `server/cstrike/addons/sourcemod/scripting/` و فایل‌های کامپایل‌شده در `server/cstrike/addons/sourcemod/plugins/` هستند.

کامپایل مجدد یک پلاگین:
```bash
cd server/cstrike/addons/sourcemod/scripting
./spcomp mypplugin.sp -o../plugins/myplugin.smx
# بعد داخل بازی یا کنسول: sm plugins reload myplugin
```

---

## VIP Perks (`vip_perks.sp`)

قابلیت‌های ویژه برای دارندگان VIP (فلگ `o` = `ADMFLAG_CUSTOM1`).

| دستور | قابلیت |
|---|---|
| `!vn` | ناکلیپ (پرواز از دیوار) — تاگل |
| `!vg` | گادمد (ضدضربه) — تاگل |
| `!vw` | وال‌هک (دیدن از دیوار) — تاگل |

فقط خود پلیر (self-only). برای دادن VIP به یک پلیر، فلگ `o` را در `addons/sourcemod/configs/admins_simple.ini` به او بدهید:
```
"STEAM_0:1:12345678" "o"
```

## Server Menu (`server_menu.sp`)

منوی فروشگاه/امکانات سرور با دستور `!smenu` برای همه‌ی پلیرها.

## Admin Panel (`admin_panel.sp` نسخه‌ی 3.0)

پنل کامل مدیریت با `!admin` یا `/admin` — فقط ادمین‌ها. راهنمای کامل منوها در [`admin-panel.md`](admin-panel.md).

## Cheater Menu (`cheater_menu.sp`)

منوی چیت با `!menu` یا `/cheat`.
- ادمین‌ها همیشه دسترسی دارند.
- ادمین می‌تواند از پنل ادمین (`!admin` ← سوپر ادمین) به یک پلیر خاص دسترسی موقت بدهد.
- دسترسی با قطع شدن پلیر از سرور باطل می‌شود.

## Quake Sounds (`quake_sounds.sp`)

افکت‌های صوتی معروف Quake برای کیل‌ها (Headshot, Humiliation و...). خودکار.

## Simple Rank (`simple_rank.sp`)

سیستم رنکینگ ساده. دستور `!rank` رتبه‌ی شما را نشان می‌دهد.

## AFK Manager (`afk_manager.sp`)

پلیرهایی که مدت طولانی AFK باشند را خودکار به اسپکتیتور می‌فرستد یا کیک می‌کند.

## Damage Display (`damage_display.sp`)

بعد از هر درگیری، دمیج واردشده/تحمل‌شده را نشان می‌دهد.

## Bomb Info (`bomb_info.sp`)

اطلاعات لحظه‌ای بمب (کاشته شدن، خنثی شدن، تایمر).

## Connect Messages (`connect_messages.sp`)

پیام ورود و خروج پلیرها در چت.

## VIP Chat Tag (`vip_chat_tag.sp`)

پلیرهای VIP تگ `[VIP]` در چت دارند.

## Join Music (`join_music.sp`)

هنگام ورود پلیر به سرور موزیک پخش می‌کند.

## Simple Ads (`simple_ads.sp`)

تبلیغات متنی دوره‌ای در چت (قابل تنظیم در `addons/sourcemod/configs/`).
