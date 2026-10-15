# سرور Counter-Strike: Source v34 — پکیج کامل راه‌اندازی

پکیج کامل یک سرور آماده‌ی **Counter-Strike: Source v34** (نسخه‌ی legacy، non-Steam) روی لینوکس؛ شامل فایل‌های سرور، پلاگین‌های سفارشی SourceMod، کانفیگ‌ها، اسکین‌ها و راهنمای قدم‌به‌قدم فارسی.

> ⚠️ **نکته‌ی امنیتی:** قبل از اجرای سرور، حتماً `rcon_password` را در `server/cstrike/cfg/server.cfg` عوض کنید (فعلاً مقدار `CHANGE_ME` گذاشته شده).

---

## مشخصات

| مورد | مقدار |
|---|---|
| نسخه‌ی بازی | Counter-Strike: Source v34 (بیلد legacy/hl2go) |
| سیستم‌عامل | Linux (تست‌شده روی Ubuntu) |
| استیم | non-Steam |
| Tickrate | 100 |
| پورت پیش‌فرض | 27015 (UDP/TCP) |
| ظرفیت | 32 پلیر |
| مپ پیش‌فرض | de_dust2 |
| SourceMod | 1.7.3-stable |
| FastDL | از طریق nginx |

## ساختار ریپو

```
counter/
├── README.md              ← همین فایل
├── docs/                  ← راهنماهای تفصیلی
│   ├── plugins.md         ← معرفی همه‌ی پلاگین‌ها و دستوراتشان
│   ├── admin-panel.md     ← راهنمای کامل پنل ادمین (!admin)
│   ├── vip.md             ← سیستم VIP و فروش
│   ├── fastdl.md          ← راه‌اندازی FastDL
│   └── troubleshooting.md ← عیب‌یابی
├── server/                ← کل فایل‌های سرور (آماده‌ی اجرا)
│   ├── srcds_run          ← فایل اجرای سرور
│   ├── cstrike/           ← مپ‌ها، کانفیگ‌ها، مدل‌ها، صداها
│   │   ├── cfg/           ← server.cfg و بقیه‌ی کانفیگ‌ها
│   │   └── addons/sourcemod/
│   │       ├── plugins/   ← پلاگین‌های کامپایل‌شده (.smx)
│   │       ├── scripting/ ← سورس پلاگین‌ها (.sp) + کامپایلر
│   │       └── configs/   ← کانفیگ پلاگین‌ها
│   └── bin/               ← باینری‌های موتور
└── tools/
    └── css34.service      ← فایل سرویس systemd
```

## راه‌اندازی سریع (۵ قدم)

```bash
# 1. ریپو را کلون کنید
git clone https://github.com/armadgarsone2/counter.git
cd counter/server

# 2. دسترسی اجرا بدهید
chmod +x srcds_run bin/*

# 3. پسورد RCON را عوض کنید (!)
nano cstrike/cfg/server.cfg   # خط rcon_password را ویرایش کنید

# 4. سرور را اجرا کنید
./srcds_run -game cstrike +map de_dust2 -maxplayers 32 -port 27015 +tickrate 100

# 5. (اختیاری) اجرای دائمی با systemd
sudo cp ../tools/css34.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now css34
```

## پلاگین‌های سفارشی

۱۱ پلاگین اختصاصی + پنل ادمین کامل. لیست کامل و دستوراتشان در [`docs/plugins.md`](docs/plugins.md):

| پلاگین | دستور | کاربرد |
|---|---|---|
| VIP Perks | `!vn` `!vg` `!vw` | ناکلیپ / گادمد / وال‌هک (فلگ `o`) |
| Server Menu | `!smenu` | منوی فروشگاه سرور |
| Admin Panel | `!admin` | پنل کامل ادمین (راهنما در `docs/admin-panel.md`) |
| Cheater Menu | `!menu` / `/cheat` | منوی چیت (فقط با دسترسی اعطاشده) |
| Quake Sounds | خودکار | افکت‌های صوتی کیل |
| Simple Rank | `!rank` | رنکینگ پلیرها |
| AFK Manager | خودکار | مدیریت پلیرهای AFK |
| Damage Display | خودکار | نمایش دمیج |
| Bomb Info | خودکار | اطلاعات بمب |
| Connect Messages | خودکار | پیام ورود/خروج |
| VIP Chat Tag | خودکار | تگ VIP در چت |
| Join Music | خودکار | موزیک ورود |

## سیستم VIP

- فلگ SourceMod برابر `o` (یعنی `ADMFLAG_CUSTOM1`)
- فروش **دستی** انجام می‌شود (ربات فروش غیرفعال است)
- جزئیات در [`docs/vip.md`](docs/vip.md)

## FastDL (دانلود سریع فایل‌ها برای پلیرها)

```nginx
# در nginx:
root /var/www/fastdl;
# آدرس: http://YOUR_SERVER_IP/cstrike/
```

راهنمای کامل در [`docs/fastdl.md`](docs/fastdl.md). داخل بازی:
```
sv_downloadurl "http://YOUR_SERVER_IP/cstrike/"
```

## اسکین‌ها

- **پک اسلحه‌ی CSO2** — جایگزین مدل‌های پیش‌فرض اسلحه‌ها
- **پک پلیر سبز/قرمز** — مدل‌های T سبز و CT قرمز
- هر دو روی FastDL هم قرار دارند تا پلیرها خودکار دانلود کنند.

## دستورات مدیریتی مهم

| دستور (چت) | کاربرد |
|---|---|
| `!admin` | پنل ادمین (فقط ادمین‌ها) |
| `!smenu` | منوی سرور (همه) |
| `!menu` / `/cheat` | منوی چیت (فقط با دسترسی) |
| `!vn` `!vg` `!vw` | قابلیت‌های VIP |

## عیب‌یابی سریع

| مشکل | راه‌حل |
|---|---|
| پلاگین لود نمی‌شود | `sm plugins list` در کنسول؛ لاگ خطا در `cstrike/addons/sourcemod/logs/` |
| اسکین دانلود نمی‌شود | `sv_downloadurl` و دسترسی nginx را چک کنید (`docs/fastdl.md`) |
| سرور در لیست نمی‌آید | پورت 27015 روی UDP باز باشد |
| `autoexec.cfg` باعث مصرف ۱۰۰٪ CPU می‌شود | در این بیلد قدیمی از `autoexec.cfg` استفاده نکنید |

جزئیات بیشتر در [`docs/troubleshooting.md`](docs/troubleshooting.md).
