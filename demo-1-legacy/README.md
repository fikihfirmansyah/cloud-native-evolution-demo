# Demo 1 — Legacy: Laravel di VPS, deploy jadul

Laravel 11 + MySQL + nginx + PHP-FPM, semua di satu VPS, tanpa Docker.
Sengaja dibuat "jadul yang jujur" — pola deploy yang masih umum di banyak
perusahaan Indonesia. Kekurangannya (downtime saat deploy, tanpa health
check, tanpa auto-recovery, susah scaling) adalah **fitur demo**, bukan bug.

## Struktur penting

```
demo-1-legacy/
├── app/Http/Controllers/ProdukController.php  # /api/produk + halaman Blade
├── app/Models/Produk.php
├── database/migrations/2026_01_01_000000_create_produk_table.php
├── database/seeders/ProdukSeeder.php           # data sama dgn shared/seed-data.sql
├── resources/views/produk.blade.php            # grid produk server-rendered
├── setup-vps.sh        # setup VPS baru sekali jalan (idempotent)
├── deploy-jadul.sh     # deploy manual: git pull + composer + restart
├── Makefile            # shortcut panggung (watch/deploy/stop-mysql/load)
└── DEMO-SCRIPT.md      # naskah kata-per-kata 3 momen
```

Yang sengaja TIDAK ada: `/api/health`, info versi, graceful shutdown,
session eksternal (session = file di disk server, `SESSION_DRIVER=file`).

## Prasyarat

1. VPS IDCloudHost Ubuntu 22.04 — 2 CPU / 2 GB RAM / 20 GB disk.
2. Akses SSH sebagai root (atau user sudo).
3. Repo ini sudah di-push ke GitHub (setup clone dari git).
4. Opsional: domain menunjuk ke IP VPS (tanpa domain pun bisa, akses via IP).
5. Di laptop: `hey` untuk load test — `go install github.com/rakyll/hey@latest`
   atau unduh binary dari https://github.com/rakyll/hey/releases

## Setup step-by-step

```bash
# 1. SSH ke VPS baru
ssh root@<IP_VPS>

# 2. Unduh dan jalankan setup (ganti REPO_URL dan DOMAIN)
curl -fsSO https://raw.githubusercontent.com/<user>/cloud-native-evolution-demo/main/demo-1-legacy/setup-vps.sh
sudo REPO_URL=https://github.com/<user>/cloud-native-evolution-demo.git \
     DOMAIN=legacy.example.com \
     bash setup-vps.sh
# ±5-10 menit. Idempotent — kalau gagal di tengah, jalankan ulang saja.

# 3. Verifikasi dari laptop
curl http://<domain-atau-IP>/api/produk   # → JSON 10 produk
# buka browser → grid katalog tampil

# 4. Setup shortcut panggung (di laptop, folder ini)
cat > .env.demo <<EOF
VPS=root@<IP_VPS>
URL=http://<domain-atau-IP>
EOF
make status   # → active active active
```

### Setup GitHub Actions (opsional tapi disarankan untuk narasi)

Repo → Settings → Secrets and variables → Actions, tambahkan:

| Secret | Isi |
|---|---|
| `VPS_HOST` | IP VPS |
| `VPS_USER` | `root` |
| `VPS_SSH_KEY` | private key SSH (buat khusus: `ssh-keygen -t ed25519 -f demo1-key`, taruh `.pub`-nya di `~/.ssh/authorized_keys` VPS) |

Workflow: `.github/workflows/demo-1-deploy-jadul.yml` (di **root** repo — GitHub
tidak membaca workflow di subfolder). Trigger: push yang menyentuh
`demo-1-legacy/**`, atau manual dari tab Actions.

## Verifikasi sebelum hari-H (H-1)

- [ ] `make status` → nginx, php8.3-fpm, mysql semua `active`
- [ ] Browser: grid 10 produk + badge `server: <hostname>` tampil
- [ ] `make watch` → hijau stabil
- [ ] Latihan momen A: `make deploy` → merah beberapa detik → hijau lagi
- [ ] Latihan momen B: `make stop-mysql` → merah; `make start-mysql` → hijau
- [ ] Latihan momen C: `make load` → watch melambat/merah sebagian
- [ ] **Rekam video ketiga momen sebagai fallback**

## Reset ulang demo

- Setelah momen B: `make start-mysql`.
- Kode berubah karena latihan deploy: revert commit lalu `make deploy`.
- Reset total (jarang perlu): jalankan ulang `setup-vps.sh` — idempotent;
  atau rebuild VPS dari image Ubuntu 22.04 lalu setup ulang (±10 menit).

## Troubleshooting

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| 502 Bad Gateway | php-fpm mati / socket beda versi | `systemctl restart php8.3-fpm`; cek path socket di vhost |
| 500 di semua halaman | MySQL mati, atau `.env` salah | `systemctl start mysql`; cek `storage/logs/laravel.log` |
| 403/404 setelah setup | root nginx salah / permission | vhost root harus `.../demo-1-legacy/public`; `chown -R www-data storage bootstrap/cache` |
| PPA PHP gagal ditambah | DNS/IPv6 VPS bermasalah | coba ulang skrip; Laravel 11 butuh PHP ≥ 8.2 jadi PPA wajib di Ubuntu 22.04 |
| Actions gagal SSH | key salah format / firewall | test manual `ssh -i demo1-key root@IP`; pastikan port 22 terbuka |
| `hey` membebani WiFi venue | — | jalankan `hey` dari VPS lain / cloud shell, bukan dari WiFi panggung |
