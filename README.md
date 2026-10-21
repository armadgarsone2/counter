<div align="center">

# 🦁 سفیدان | Wh1Tes

### ⚔️ Counter-Strike: Source v34 — سرور رفقا، بدون تعارف ⚔️

![Game](https://img.shields.io/badge/Game-CS%3AS%20v34-orange?style=for-the-badge)
![SourceMod](https://img.shields.io/badge/SourceMod-1.7.3--css34-blue?style=for-the-badge)
![Tickrate](https://img.shields.io/badge/Tickrate-100-red?style=for-the-badge)
![Location](https://img.shields.io/badge/Server-Sweden%20🇸🇪-yellow?style=for-the-badge)
![Players](https://img.shields.io/badge/Players-32-green?style=for-the-badge)

**مدل‌های واقعی Modern Warfare، پول مکس هر راند، فریزتایم صفر — راند شروع شد، دعوا شروع شد.**

```
connect 13.53.151.178:27015
```

</div>

---

## 🔥 چی تو این سروره؟

| قابلیت | توضیح |
|---|---|
| 🎭 **مدل‌های واقعی پلیر** | Ghost، TF141 ،Gorka ،Juggernaut و Spetsnaz — نه رنگی‌رنگی، مدل واقعی |
| 💰 **پول مکس هر راند** | شروع هر راند: **۱۶٬۰۰۰$** برای همه — غر زدن سر پول تمومه |
| 🧊 **فریزتایم: صفر** | راند که شروع شد، همون لحظه اکشنه؛ وایسادن نداریم |
| 🎯 **نمایش دمیج زنده** | هر تیرت وسط صفحه میاد: چند HP و چند Armor کم کردی + HP باقی‌مونده‌ی حریف |
| 💣 **Bomb Info** | تایمر C4 + فاصله‌ت تا بمب + دمیجی که می‌خوری — قبل از اینکه بترکی حساب کن |
| 🌫️ **دود غلیظ** | دودزا یعنی دود؛ از اون‌ور دیده نمی‌شی |
| 📜 **منوی فارسی `!smenu`** | قوانین و اطلاعات سرور، با فارسی درست‌وحسابی |
| 🛡️ **پنل ادمین `!admin`** | مدیریت کامل سرور از توی خود بازی |
| 🏆 **رنک و آمار** | `!rank` — کی بیشتر زده، کی بیشتر خورده |
| 🔊 **Quake Sounds + موزیک** | افکت‌های کیل و موزیک ورود |

---

## 🎭 مدل‌ها

| تیم | کلاس | مدل |
|---|---|---|
| CT | GIGN | 👻 **MW2 Ghost** |
| CT | GSG9 / SAS / Urban | 🎖️ **TF141** |
| T | Phoenix | 🪖 **Gorka** |
| T | Leet | 🔫 **Russian Mercenary** |
| T | Guerilla | 🐗 **Juggernaut** |
| T | Arctic | ❄️ **MW3 Spetsnaz** |

مدل‌ها از مسیر اختصاصی با پلاگین **Wh1Tes Models** اعمال می‌شن و از FastDL خودکار دانلود می‌شن — هیچ کاری لازم نیست بکنی، فقط وصل شو.

> ⚠️ اسلحه‌ها استاک‌ان و دست‌نخورده. اینجا مهارت حرف می‌زنه، نه اسکین گان.

---

## 📜 قوانین خونه

```
1. فحاشی و توهین به پلیرها ممنوع
2. چیت، اسکریپت و سوءاستفاده از باگ ممنوع
3. اسپم میکروفون و چت ممنوع
4. کمپ کردن پشت اسپاون حریف ممنوع
5. به ادمین‌ها احترام بذار
```

---

## 🗂️ ساختار ریپو

```
counter/
├── README.md                  ← همین فایل
├── server/                    ← کل سرور، آماده‌ی اجرا
│   ├── srcds_run
│   └── cstrike/
│       ├── cfg/               ← کانفیگ‌ها + حالت‌های بازی (gamemodes)
│       ├── addons/sourcemod/
│       │   ├── plugins/       ← پلاگین‌های کامپایل‌شده (.smx)
│       │   ├── scripting/     ← سورس پلاگین‌ها (.sp) — پوشه‌ی wh1tes = کارهای اختصاصی ما
│       │   └── configs/
│       └── maps/  models/  materials/  sound/
├── css-bot/                   ← بات مدیریت تلگرام (RCON، حالت‌های بازی، بکاپ)
├── tools/                     ← اسکریپت‌های تحلیل و ساخت پلاگین + سرویس systemd
├── skills/                    ← اسکیل‌های مدیریتی سرور (داکیومنت زنده‌ی تجربه‌ها)
└── docs/                      ← راهنماهای تفصیلی
```

---

## 🚀 راه‌اندازی سریع

```bash
# 1. کلون
git clone https://github.com/armadgarsone2/counter.git
cd counter/server

# 2. دسترسی اجرا
chmod +x srcds_run bin/*

# 3. ⚠️ پسورد RCON رو عوض کن (توی فایل الان CHANGE_ME ـه)
nano cstrike/cfg/server.cfg

# 4. اجرا
./srcds_run -game cstrike +map de_dust2 -maxplayers 32 -port 27015 +tickrate 100

# 5. (اختیاری) سرویس دائمی
sudo cp ../tools/css34.service /etc/systemd/system/
sudo systemctl enable --now css34
```

**FastDL:** فایل‌ها با nginx سرو می‌شن تا پلیرها مدل‌ها رو با سرعت کامل بگیرن:

```
sv_downloadurl "http://YOUR_SERVER_IP/cstrike/"
```

---

## 🧩 پلاگین‌های اختصاصی (Wh1Tes)

| پلاگین | کارش |
|---|---|
| **Wh1Tes Models** | مدل‌های واقعی هر کلاس + جدول دانلود بهینه |
| **Wh1Tes Round Money** | پول ۱۶٬۰۰۰ هر راند + فریزتایم صفر (قوانین کلاسیک) |
| **Wh1Tes Damage Info** | نمایش HP/Armor کم‌شده زیر کراس‌هیر |
| **Wh1Tes Dense Smoke** | دود غلیظ‌تر برای دودزاها |
| **Bomb Info** | تایمر، فاصله و دمیج بمب |

به‌علاوه‌ی: پنل ادمین، منوی سرور، رنک، AFK منیجر، پیام اتصال، Quake Sounds و بات مدیریت تلگرام.

---

## ⚙️ زیر کاپوت (برای اهل فن)

- این بیلد قدیمی فقط پلاگین کامپایل‌شده با **SourceMod 1.9** رو سالم اجرا می‌کنه؛ 1.12 لود نمی‌شه، 1.10 کرش می‌ده. قانون طلاییه.
- جدول دانلود (Downloads Table) سقف داره: زیادی پرش کنی کلاینت موقع اتصال کرش می‌کنه. لیست دقیق و حساب‌شده نگهش دار.
- مسیرهای متریال تو فایل‌های مدل رو **case-insensitive** حل کن؛ لینوکس با حروف بزرگ/کوچک شوخی نداره و خروجی‌ش پلیر بنفشه.
- متن فارسی خام تو انجین به‌هم‌ریخته رندر می‌شه — یا انگلیسی بنویس یا با reshaper درستش کن.
- جزئیات کامل همه‌ی این تجربه‌ها توی `skills/` هست.

---

<div align="center">

**سرور دوستانه‌ست و غیرتجاری — فروش VIP نداریم، رفیق‌بازیه.** 🤝

ساخته‌شده با ☕ و 🎧 روی یه سرور کوچیک تو استکهلم

</div>
