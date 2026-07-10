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

## Urutan pengerjaan yang disarankan

1. **Demo 2 dulu** (paling penting — inti presentasi): setup server Docker,
   DNS, GHCR, Portainer webhook. Latih ketiga momen.
2. **Demo 1**: VPS IDCloudHost baru, jalankan `setup-vps.sh`, latih momen
   downtime.
3. **Demo 3**: `terraform apply` (⚠️ biaya per jam — apply H-1 saja),
   seed Aurora, rekam video auto-scaling.

Detail setup ada di `README.md` masing-masing demo; naskah panggung
kata-per-kata ada di `DEMO-SCRIPT.md` masing-masing.

## Checklist H-1 gabungan

### Infrastruktur
- [ ] Demo 1: VPS hidup, situs jalan, `deploy-jadul.sh` teruji
- [ ] Demo 2: stack sehat (`make ps`), webhook Portainer teruji end-to-end
- [ ] Demo 3: `terraform apply` selesai, ECS 2 task healthy, Aurora terseed,
      CloudFront serve frontend
- [ ] DNS semua domain resolve dari jaringan venue (tes pakai tethering HP!)

### Latihan tiap momen (jalankan sekali penuh)
- [ ] D1-a deploy downtime · D1-b MySQL mati · D1-c load test keteteran
- [ ] D2-a zero-downtime deploy · D2-b kill container · D2-c scale 5
- [ ] D3-a tur console · D3-b desired-count 4 · D3-c video auto-scaling

### Video fallback (rekam SEMUA momen — internet venue tidak bisa dipercaya)
- [ ] Rekam layar tiap momen di atas (9 video pendek)
- [ ] Video auto-scaling demo-3 (wajib — terlalu lambat untuk live)
- [ ] Simpan video offline di laptop, bukan di cloud

### Panggung
- [ ] Font terminal ≥ 18pt, tema kontras tinggi
- [ ] Browser zoom 125-150%
- [ ] Tab tersusun: web demo, Portainer, GitHub Actions, AWS Console
- [ ] `make help` di tiap demo untuk contekan perintah
- [ ] Hotspot HP sebagai backup internet

### Setelah acara
- [ ] **`terraform destroy` demo-3** — Aurora + ALB + NAT jalan terus = biaya!
- [ ] Matikan/hapus VPS demo kalau tidak dipakai lagi
