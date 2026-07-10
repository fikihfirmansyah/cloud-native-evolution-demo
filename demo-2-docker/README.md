# Demo 2 — Go + Svelte di Docker (Traefik + Portainer, 1 server)

Aplikasi katalog produk cloud-native: API Go (stdlib) + frontend Svelte +
PostgreSQL, semua dalam container, routing + TLS otomatis via Traefik,
CI/CD via GitHub Actions → GHCR → Portainer webhook.

**Poin presentasi:** kode di folder `api/` dan `web/` ini juga yang di-deploy
ke AWS di demo-3 — tanpa modifikasi satu baris pun.

## Struktur

```
demo-2-docker/
├── api/          # Go 1.22+ stdlib net/http + pgx (~250 baris, muat di slide)
├── web/          # Svelte + Vite, grid produk + badge handledBy/version
├── infra/        # referensi setup Traefik+Portainer untuk server baru
├── scripts/      # watch.sh (loop proyektor), rollout.sh (rolling deploy manual)
├── docker-compose.yml
├── Makefile      # shortcut panggung: make watch / kill-one / scale-5
└── DEMO-SCRIPT.md
```

## Prasyarat

1. Server Ubuntu dengan Docker Engine + Docker Compose v2.
2. Traefik + Portainer sudah jalan dengan external network `proxy-net`
   (setup standar). Kalau server baru dari nol: lihat
   `infra/traefik-portainer-compose.yml`.
3. DNS A record menunjuk ke IP server untuk **kedua** domain:
   - `demo.example.com` (web)
   - `api.demo.example.com` (api)
4. Repo GitHub dengan secrets/variables terkonfigurasi (lihat bagian CI/CD).

## Setup step-by-step

```bash
# 1. Clone repo di server
git clone <REPO_URL> && cd cloud-native-evolution-demo/demo-2-docker

# 2. Konfigurasi
cp .env.example .env
nano .env   # isi DOMAIN_WEB, DOMAIN_API, POSTGRES_PASSWORD

# 3. Start (build lokal pertama kali)
docker compose build
make up     # = docker compose up -d --scale api=3

# 4. Verifikasi
make ps                            # semua Up (healthy)
make seed-check                    # 10 produk muncul
curl https://api.demo.example.com/api/health
# → {"status":"ok","handledBy":"<container-id>","version":"dev"}
```

### Setup CI/CD (Portainer webhook)

1. Di Portainer: **Stacks → Add stack → Repository**, arahkan ke repo ini,
   compose path `demo-2-docker/docker-compose.yml`, isi env variables.
2. Setelah stack dibuat: buka stack → **Webhooks** → aktifkan → salin URL.
3. Di GitHub repo: **Settings → Secrets and variables → Actions**
   - Secret `PORTAINER_WEBHOOK_URL` = URL webhook tadi
   - Variable `DOMAIN_API` = `api.demo.example.com`
4. Catatan: workflow ada di **root repo** `.github/workflows/demo-2-deploy.yml`
   (GitHub tidak membaca workflow di subfolder), dengan filter `paths`
   sehingga hanya jalan saat demo-2 berubah.

## Verifikasi sebelum hari-H (H-1)

- [ ] `make ps` → 3 replica api + web + postgres semua healthy
- [ ] Buka `https://demo.example.com` → grid 10 produk + badge tampil
- [ ] `make watch` → baris berjalan, `instance` bergantian antar 3 replica
- [ ] Push commit dummy → Actions hijau → badge versi berubah (latihan Momen A)
- [ ] `make kill-one` → tidak ada FAIL di watch, container nyala lagi (Momen B)
- [ ] `make scale-5` lalu `make scale-3` (Momen C)
- [ ] **Rekam video ketiga momen sebagai fallback**

## Reset ulang demo

```bash
make reset          # hapus container + volume, start ulang, seed otomatis
```

Untuk mengembalikan versi app ke keadaan sebelum demo: revert commit demo
lalu push (CI deploy ulang), atau `git reset --hard <sha> && git push -f`
kalau repo demo pribadi.

## Troubleshooting

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| 404 dari Traefik | label router salah / domain tidak match | cek `docker compose config` — nilai `Host()` sesuai DNS |
| Cert TLS invalid | DNS belum propagate saat Traefik minta cert | tunggu propagate, restart traefik agar retry ACME |
| `network proxy-net not found` | network external belum dibuat | `docker network create proxy-net` |
| api restart terus | Postgres belum siap / DATABASE_URL salah | `make logs` — connectDB retry 10x, cek password di .env |
| Produk kosong | seed hanya jalan saat volume pertama dibuat | `make reset` (hapus volume → seed ulang) |
| Port 80/443 bentrok | nginx/apache lama masih jalan di host | `sudo systemctl disable --now nginx` |
| Webhook tidak memicu deploy | URL webhook salah / Portainer di belakang auth | test manual: `curl -X POST $URL` → cek response 2xx |
| Badge frontend `API DOWN` | CORS / API base URL build salah | cek `VITE_API_BASE` build arg = domain API benar |
