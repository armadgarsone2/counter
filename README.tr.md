<div align="center">

[🇮🇷 فارسی](README.md) • [🇬🇧 English](README.en.md) • [🇷🇺 Русский](README.ru.md) • [🇹🇷 Türkçe](README.tr.md)

<p align="center"><img src="assets/banner.jpg" alt="Sefidan | Wh1Tes — Counter-Strike: Source v34" width="100%"></p>
<p align="center">🌐 <a href="https://armadgarsone2.github.io/counter/tr/">Sunucu Web Sitesi</a></p>


# 🦁 Sefidan | Wh1Tes

### ⚔️ Counter-Strike: Source v34 — arkadaş sunucusu, acımak yok ⚔️

![Game](https://img.shields.io/badge/Game-CS%3AS%20v34-orange?style=for-the-badge)
![SourceMod](https://img.shields.io/badge/SourceMod-1.7.3--css34-blue?style=for-the-badge)
![Tickrate](https://img.shields.io/badge/Tickrate-100-red?style=for-the-badge)
![Location](https://img.shields.io/badge/Server-Sweden%20🇸🇪-yellow?style=for-the-badge)
![Players](https://img.shields.io/badge/Players-32-green?style=for-the-badge)

**Gerçek Modern Warfare oyuncu modelleri, her round maksimum para, sıfır donma süresi — round başladı, savaş başladı.**

```
connect 13.53.151.178:27015
```

</div>

---

## 🔥 İçinde ne var?

| Özellik | Açıklama |
|---|---|
| 🎭 **Gerçek oyuncu modelleri** | Ghost, TF141, Gorka, Juggernaut ve Spetsnaz — boyama değil, gerçek modeller |
| 💰 **Her round maksimum para** | Her round herkes **16.000$** ile başlar — para sızlanması bitti |
| 🧊 **Donma süresi: sıfır** | Round başlar, aksiyon başlar. Beklemek yok |
| 🎯 **Canlı hasar göstergesi** | Her vuruş nişangâhın altında gösterir: kaç HP ve Armor aldın + düşmanın kalan HP'si |
| 💣 **Bomb Info** | C4 sayacı + bombaya mesafen + alacağın hasar — patlamadan önce hesapla |
| 🌫️ **Yoğun sis** | Gerçekten sis yapan sis bombası. Arkası görünmez |
| 📜 **Oyun içi menü `!smenu`** | Sunucu kuralları ve bilgileri, oyunun içinden |
| 🛡️ **Admin paneli `!admin`** | Oyunun içinden tam sunucu yönetimi |
| 🏆 **Rütbe ve istatistik** | `!rank` — kim taşıyor, kim besliyor |
| 🔊 **Quake Sounds + müzik** | Kill efektleri ve giriş müziği |

---

## 🎭 Modeller

| Takım | Sınıf | Model |
|---|---|---|
| CT | GIGN | 👻 **MW2 Ghost** |
| CT | GSG9 / SAS / Urban | 🎖️ **TF141** |
| T | Phoenix | 🪖 **Gorka** |
| T | Leet | 🔫 **Russian Mercenary** |
| T | Guerilla | 🐗 **Juggernaut** |
| T | Arctic | ❄️ **MW3 Spetsnaz** |

Modeller, **Wh1Tes Models** eklentisiyle sınıfa özel yollardan uygulanır ve FastDL ile otomatik iner — sadece bağlan ve oyna.

> ⚠️ Silahlar %100 stok. Burada konuşan yetenek, silah skini değil.

---

## 📜 Ev kuralları

```
1. Oyunculara hakaret ve küfür yasak
2. Hile, script ve bug suistimali yasak
3. Mikrofon/sohbet spamı yasak
4. Düşman spawnı arkasında kamp yasak
5. Adminlere saygı göster
```

---

## 🗂️ Repo yapısı

```
counter/
├── README.md                  ← ana sürüm (Farsça)
├── README.en.md / README.ru.md / README.tr.md
├── server/                    ← sunucunun tamamı, çalışmaya hazır
│   ├── srcds_run
│   └── cstrike/
│       ├── cfg/               ← configler + oyun modları (gamemodes)
│       ├── addons/sourcemod/
│       │   ├── plugins/       ← derlenmiş eklentiler (.smx)
│       │   ├── scripting/     ← eklenti kaynakları (.sp) — wh1tes klasörü bizim özel işler
│       │   └── configs/
│       └── maps/  models/  materials/  sound/
├── css-bot/                   ← Telegram yönetim botu (RCON, oyun modları, yedekler)
├── tools/                     ← analiz/build scriptleri + systemd servisi
├── skills/                    ← sunucu yönetim skilleri (tecrübelerin canlı dokümanı)
└── docs/                      ← detaylı rehberler
```

---

## 🚀 Hızlı başlangıç

```bash
# 1. Klonla
git clone https://github.com/armadgarsone2/counter.git
cd counter/server

# 2. Çalıştırma izni
chmod +x srcds_run bin/*

# 3. ⚠️ RCON şifresini değiştir (dosyada CHANGE_ME yazıyor)
nano cstrike/cfg/server.cfg

# 4. Çalıştır
./srcds_run -game cstrike +map de_dust2 -maxplayers 32 -port 27015 +tickrate 100

# 5. (İsteğe bağlı) servis olarak
sudo cp ../tools/css34.service /etc/systemd/system/
sudo systemctl enable --now css34
```

**FastDL:** dosyalar nginx ile sunulur, oyuncular modelleri tam hızda çeker:

```
sv_downloadurl "http://YOUR_SERVER_IP/cstrike/"
```

---

## 🧩 Özel eklentiler (Wh1Tes)

| Eklenti | İşi |
|---|---|
| **Wh1Tes Models** | Sınıfa özel gerçek modeller + optimize indirme tablosu |
| **Wh1Tes Round Money** | Her round 16.000$ + sıfır donma (klasik kurallar) |
| **Wh1Tes Damage Info** | Alınan HP/Armor'ı nişangâh altında gösterir |
| **Wh1Tes Dense Smoke** | Daha yoğun sis bombaları |
| **Bomb Info** | Bomba sayacı, mesafe ve hasar |

Ayrıca: admin paneli, sunucu menüsü, rütbeler, AFK yöneticisi, bağlantı mesajları, Quake Sounds ve Telegram yönetim botu.

---

## ⚙️ Kaputun altında (teknik tayfaya)

- Bu eski build, yalnızca **SourceMod 1.9** ile derlenen eklentileri stabil çalıştırır; 1.12 yüklenmez, 1.10 sunucuyu düşürür. Altın kural.
- İndirme tablosunun bir tavanı var: fazla doldurursan gerçek istemciler bağlanırken çöker. Listeyi kesin ve hafif tut.
- .mdl dosyalarındaki materyal yollarını **büyük/küçük harf duyarsız** çöz; Linux harf konusunda ciddi, hatanın bedeli mor oyuncular.
- Bu motor, ham Farsça metni bozuk render eder — ya İngilizce yaz ya da önce reshape yap.
- Savaş hikâyelerinin tamamı `skills/` içinde.

---

<div align="center">

**Sadece arkadaşlara özel, ticari olmayan bir sunucu — VIP satışı yok, sadece tayfa.** 🤝

Stockholm'de küçük bir makinede ☕ ve 🎧 ile yapıldı

</div>

---

### 🔎 Anahtar kelimeler

Counter-Strike: Source v34 dedicated server kurma (srcds) — tam sunucu paketi: SourceMod 1.7.3 eklentileri, Metamod, özel oyuncu modelleri (MW2 Ghost, TF141, Gorka, Juggernaut, MW3 Spetsnaz), FastDL, klasik oyun modu, Telegram admin botu. Linux için hazır CS:S v34 sunucusu indir.
