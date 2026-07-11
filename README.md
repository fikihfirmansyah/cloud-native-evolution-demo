# Cloud-Native Evolution Demo

Materi demo untuk presentasi **"Cloud-Native Development"** — AWS Student
Community Day Medan 2026. Tiga demo dengan aplikasi berfungsi identik
(API katalog produk + frontend), tapi arsitektur dan cara deploy yang
berevolusi: dari VPS jadul → Docker satu server → cloud-native penuh di AWS.

**Poin utama:** kode aplikasi demo-2 dan demo-3 **100% identik** — hanya
konfigurasi deploy yang berbeda. Aplikasi yang ditulis cloud-native jalan
di mana saja tanpa modifikasi.

## Perbandingan tiga demo

| Aspek | Demo 1 — Legacy | Demo 2 — Docker | Demo 3 — AWS |
|---|---|---|---|
| Stack | Laravel 11 + MySQL | Go + Svelte + Postgres | Go + Svelte + Aurora (kode = demo-2) |
| Infrastruktur | VPS tunggal, nginx + PHP-FPM | 1 server + Docker + Traefik + Portainer | ECS Fargate + ALB + Aurora Serverless v2 + S3/CloudFront |
| Deploy | SSH + git pull + restart | Push → GHCR → Portainer webhook | Push → ECR → ECS rolling deploy |
| Downtime saat deploy | ✅ Ada (fitur demo!) | ❌ Praktis nol | ❌ Nol (rolling) |
| Kalau proses mati | Mati sampai manusia SSH | Restart otomatis (detik) | Task diganti otomatis |
| Scaling | Beli server lebih besar | `--scale api=5` (1 server) | Auto scaling CPU-based, multi-AZ |
| Kalau server mati | Semua mati | Semua mati (masih 1 server) | Tetap hidup (2 AZ) |
| State | Session file di server | Stateless | Stateless |
| Health check | Tidak ada | `/api/health` + Docker healthcheck | `/api/health` + ALB target group |

## Struktur repo

```
cloud-native-evolution-demo/
├── demo-1-legacy/     # Laravel di VPS, deploy jadul (downtime = fitur demo)
├── demo-2-docker/     # Go + Svelte, Docker + Traefik + Portainer
├── demo-3-aws/        # aplikasi yang SAMA → ECS Fargate + Aurora
├── shared/
│   └── seed-data.sql  # data produk Medan yang sama untuk semua demo
└── .github/workflows/ # semua workflow di root (GitHub tidak baca subfolder),
                       # dipisah dengan filter `paths` per demo
```
