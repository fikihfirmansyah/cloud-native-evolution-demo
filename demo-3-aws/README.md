# Demo 3 — AWS: aplikasi yang SAMA, ECS Fargate + Aurora

Aplikasi Go + Svelte **dari demo-2, tanpa modifikasi satu baris pun**,
di-deploy cloud-native penuh di AWS Jakarta (`ap-southeast-3`):

- **ECS Fargate** — 2-6 task, auto scaling CPU 60%, rolling deploy, 2 AZ
- **ALB** — health check `/api/health`, load balancing antar task
- **Aurora Serverless v2 PostgreSQL** — 0.5-1 ACU, private subnet
- **Secrets Manager** — `DATABASE_URL` di-inject ke task
- **S3 + CloudFront** — frontend statis dari edge
- **ECR** — registry image

Folder ini sengaja **tidak punya source code** — build context CI menunjuk
`demo-2-docker/api` dan `demo-2-docker/web`. Itulah pembuktian poin
presentasi.

## ⚠️ BIAYA — BACA DULU

Stack ini ±**$2-3/hari** selama hidup (ALB ≈ $0.7, Aurora 0.5 ACU ≈ $1.7,
2 task Fargate ≈ $0.7). **Apply H-1, `terraform destroy` SEGERA setelah
acara.** Estimasi per komponen ada di komentar tiap file `.tf`.

## Struktur

```
demo-3-aws/
├── terraform/          # satu folder, per-file per-concern
│   ├── providers.tf    # region Jakarta + peringatan destroy
│   ├── variables.tf
│   ├── vpc.tf          # VPC 2 AZ + security group berantai ALB→ECS→Aurora
│   ├── alb.tf          # ALB + target group /api/health
│   ├── ecs.tf          # ECR, cluster, task def, service, auto scaling
│   ├── aurora.tf       # Aurora Serverless v2 0.5-1 ACU
│   ├── secrets.tf      # DATABASE_URL di Secrets Manager
│   ├── seed.tf         # task one-off seed database
│   ├── frontend.tf     # S3 private + CloudFront OAC
│   └── outputs.tf      # URL + perintah seed siap-copas
├── Makefile            # make watch / scale-4 / status / destroy
├── seed-aurora.md      # cara seed Aurora (satu cara: ECS one-off task)
├── DEMO-SCRIPT.md      # naskah momen A/B/C + narasi penutup
└── README.md
```

## Prasyarat

1. Akun AWS + IAM user/role dengan akses admin ke region `ap-southeast-3`
   (untuk terraform apply). AWS CLI v2 terkonfigurasi di laptop.
2. Terraform ≥ 1.5 (`terraform version`).
3. Repo GitHub dengan secrets/variables (tabel di bawah).
4. `hey` untuk load test rekaman auto-scaling.

## Setup step-by-step

```bash
cd demo-3-aws

# 1. Provision infra (±15-20 menit, Aurora paling lama)
make apply          # = terraform init && terraform apply

# 2. Catat outputs → isi GitHub variables (tabel di bawah)
make outputs

# 3. Seed database (detail: seed-aurora.md)
make seed
# verifikasi: curl "$(cd terraform && terraform output -raw alb_url)/api/produk"
# CATATAN: task api pertama akan gagal start sebelum ada image di ECR — wajar.

# 4. Deploy aplikasi: push ke main (atau trigger manual workflow
#    "Demo 3 - Deploy AWS" dari tab Actions)
# 5. Setelah workflow hijau: buka cloudfront_url → grid produk + badge task ID
```

### Konfigurasi GitHub Actions

Workflow: `.github/workflows/demo-3-deploy-aws.yml` (root repo). Butuh:

| Jenis | Nama | Nilai |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | access key IAM user demo (hapus user setelah acara) |
| Secret | `AWS_SECRET_ACCESS_KEY` | pasangannya |
| Variable | `AWS_REGION` | `ap-southeast-3` |
| Variable | `ECR_REPOSITORY_URL` | output `ecr_repository_url` |
| Variable | `ECS_CLUSTER` | output `ecs_cluster_name` |
| Variable | `ECS_SERVICE` | output `ecs_service_name` |
| Variable | `S3_BUCKET_WEB` | output `s3_bucket_web` |
| Variable | `CLOUDFRONT_DIST_ID` | output `cloudfront_distribution_id` |

Catatan arsitektur frontend: CloudFront meneruskan `/api/*` ke ALB
(origin kedua), jadi frontend fetch same-origin (`VITE_API_BASE` kosong).
Tidak ada masalah mixed-content http/https, tidak perlu cert/domain di
ALB. URL ALB tetap berguna untuk `curl` langsung saat demo/verifikasi.

## Verifikasi sebelum hari-H (H-1)

- [ ] `make status` → running=2, rollout=COMPLETED
- [ ] Target group: 2 target healthy
- [ ] `curl <alb_url>/api/health` → JSON dengan task ID
- [ ] CloudFront URL → grid produk + badge (cek mixed-content!)
- [ ] `make scale-4` lalu `make scale-2` (latihan momen B)
- [ ] Push dummy → workflow hijau → badge versi berubah (rolling deploy)
- [ ] **Rekam video auto-scaling** (panduan di DEMO-SCRIPT.md momen C)
- [ ] Rekam video fallback momen A & B
- [ ] Console AWS: login tersimpan, region Jakarta, tab tersusun

## Reset ulang demo

- Setelah momen B: `make scale-2`.
- Data produk berubah: jalankan ulang `make seed` (idempotent).
- Infra rusak parah: `make destroy` lalu `make apply` ulang (±20 menit) —
  jangan lakukan di hari-H.

## Troubleshooting

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Task terus STOPPED | image `:latest` belum ada di ECR | jalankan workflow deploy dulu |
| Task STOPPED: secret error | execution role belum propagate | tunggu 1-2 menit, ECS retry sendiri |
| ALB 503 | belum ada target healthy | `make tasks` + `make events` |
| `/api/produk` → error database | Aurora belum available / belum seed | cek status cluster; `make seed` |
| Apply gagal di Aurora engine_version | versi tidak tersedia di Jakarta | cek versi: perintah ada di komentar `aurora.tf` |
| Frontend blank | `VITE_API_BASE` salah saat build | cek variable `ALB_URL`, jalankan ulang workflow |
| Badge `API DOWN` di CloudFront | mixed content http/https | lihat catatan HTTPS di atas |
| Biaya jalan terus setelah acara | **lupa destroy** | `make destroy` SEKARANG |
