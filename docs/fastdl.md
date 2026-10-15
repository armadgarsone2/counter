# راه‌اندازی FastDL

FastDL باعث می‌شود پلیرها فایل‌های سفارشی (اسکین‌ها، صداها، مدل‌ها) را با سرعت بالا از وب دانلود کنند، نه با سرعت کند خودِ سرور بازی.

## سمت سرور وب (nginx)

```nginx
server {
    listen 80;
    server_name YOUR_SERVER_IP;
    root /var/www/fastdl;

    location / {
        autoindex on;
    }
}
```

فایل‌ها را با حفظ ساختار پوشه‌ای `cstrike` داخل `/var/www/fastdl` کپی کنید:
```
/var/www/fastdl/
├── materials/
├── models/
├── sound/
└   ...
```

## سمت سرور بازی

در `server/cstrike/cfg/server.cfg`:
```
sv_downloadurl "http://YOUR_SERVER_IP/cstrike/"
sv_allowdownload 1
sv_allowupload 1
```

> ⚠️ انتهای `sv_downloadurl` حتماً `/` داشته باشد و مسیر `cstrike/` را شامل شود.

## تست

```bash
curl -I http://YOUR_SERVER_IP/cstrike/materials/example.vmt
# باید HTTP 200 بدهد
```
