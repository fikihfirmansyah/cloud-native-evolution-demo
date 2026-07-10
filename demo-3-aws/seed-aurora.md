# Seed database Aurora

Aurora berada di private subnet — tidak bisa di-`psql` langsung dari laptop.
Cara paling sederhana (dan satu-satunya yang didokumentasikan di sini):
**ECS one-off task** yang sudah disiapkan Terraform.

Cara kerjanya: task Fargate sekali-jalan memakai image `postgres:16-alpine`,
menerima `DATABASE_URL` dari Secrets Manager (mekanisme yang sama dengan
task api), dan menjalankan `psql` dengan isi `shared/seed-data.sql` yang
sudah di-embed ke task definition oleh Terraform. Tidak perlu bastion,
tidak perlu membuka akses database keluar.

## Langkah

```bash
cd demo-3-aws/terraform

# 1. Perintah run-task lengkap sudah disiapkan sebagai output:
terraform output -raw seed_command

# 2. Jalankan perintah yang tercetak (copy-paste), contoh bentuknya:
aws ecs run-task \
  --region ap-southeast-3 \
  --cluster demo3-cluster \
  --task-definition demo3-seed \
  --launch-type FARGATE \
  --network-configuration 'awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}'
```

## Verifikasi

```bash
# 1. Tunggu task selesai (STOPPED, exit code 0) — ±30-60 detik
aws ecs list-tasks --cluster demo3-cluster --desired-status STOPPED --region ap-southeast-3

# 2. Cek log — harus ada baris "SEED-BERHASIL" dan "INSERT 0 10"
aws logs tail /ecs/demo3-api --region ap-southeast-3 --since 5m | grep -A2 seed

# 3. Bukti akhir: API mengembalikan produk
curl "$(terraform output -raw alb_url)/api/produk"
# → JSON 10 produk Medan
```

## Catatan

- Seed **idempotent** (`ON CONFLICT DO NOTHING`) — aman dijalankan ulang.
- Kalau task gagal: cek log stream prefix `seed` di log group `/ecs/demo3-api`.
  Penyebab paling umum: Aurora belum selesai provisioning (tunggu status
  cluster `available`), atau task dijalankan sebelum `terraform apply` beres.
- Task berhenti sendiri setelah selesai — tidak ada biaya berjalan.
