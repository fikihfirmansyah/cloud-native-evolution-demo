# Skrip Demo 3 — AWS (ECS Fargate + Aurora)

> Persiapan sebelum naik panggung:
> - `terraform apply` sudah selesai H-1, Aurora terseed, deploy pertama sukses
> - `make status` → running=2, rollout=COMPLETED
> - Browser tab: CloudFront URL (halaman produk + badge), AWS Console
>   (ECS service, Aurora, target group) — SUDAH LOGIN, region Singapura
> - Terminal 1: siap `make watch`
> - Terminal 2: perintah demo
> - **Video auto-scaling sudah direkam H-1** (momen C tidak live)

---

## Momen A — Tur console (live, aman)

**Narasi:**

> "Aplikasi yang kalian lihat sekarang — persis sama dengan demo Docker tadi — sedang berjalan di data center AWS di Singapura. Mari kita lihat isinya."

**Urutan tab (2-3 menit, jangan lama-lama):**

1. **ECS → Cluster → Service `demo3-api`:**
   > "Dua task berjalan, di dua Availability Zone berbeda — dua gedung data center terpisah. Satu gedung kebanjiran, aplikasi tetap hidup. Ini yang tidak mungkin dilakukan satu VPS, semurah apa pun."

2. **Target group → Targets:**
   > "Load balancer mengecek `/api/health` tiap 15 detik — endpoint yang sama yang dipakai Docker healthcheck di demo-2. Dua target, dua-duanya healthy."

3. **Aurora:**
   > "Databasenya Aurora Serverless — dia menyesuaikan kapasitasnya sendiri, dan AWS yang mengurus backup, patching, failover. Tidak ada lagi `systemctl start mysql` jam 3 pagi."

4. Buka CloudFront URL di browser:
   > "Dan frontend-nya dilayani dari edge CDN — bukan dari server kita sama sekali. Perhatikan badge-nya: `handledBy` sekarang menunjukkan ID task Fargate."

---

## Momen B — Scaling live

**Narasi:**

> "Di demo Docker, saya scaling dengan satu perintah — tapi tetap di satu server. Sekarang perhatikan ini."

**Langkah:**

1. Terminal 1:

   ```bash
   make watch
   ```

2. Terminal 2:

   ```bash
   make scale-4
   # = aws ecs update-service --desired-count 4
   ```

3. Buka tab ECS → Tasks, refresh:

   > "Dua task baru statusnya Provisioning → Pending → Running. AWS sedang mencari tempat di data center-nya, menyalakan micro-VM, menarik image, health check — semua otomatis."

4. Setelah ±60-90 detik, tunjuk Terminal 1 dan badge browser:

   > "Empat nama instance sekarang bergantian. Dan ini bukan empat proses di satu server — ini empat VM terpisah di dua gedung berbeda, yang saya sewa per detik."

5. Kembalikan:

   ```bash
   make scale-2
   ```

**Pemulihan:** `make scale-2`. Task turun sendiri dalam ±1 menit.

---

## Momen C — Auto-scaling (VIDEO, direkam H-1)

Auto-scaling butuh 5-10 menit penuh (load naik → metrics masuk → alarm →
scale out) — terlalu lambat dan terlalu berisiko untuk live. Rekam H-1.

### Cara merekam (H-1)

1. Siapkan layar rekaman (OBS / screen record) berisi 3 panel:
   - Terminal `make watch`
   - Console ECS → service → tab **Tasks**
   - CloudWatch: metric `ECS/ContainerInsights → CPUUtilization` service
     (period 1 menit) + `RunningTaskCount` — atau tab **Health and metrics**
     di halaman service (Container Insights sudah diaktifkan Terraform)

2. Mulai rekam, lalu jalankan beban dari terminal lain:

   ```bash
   make load
   # = hey -z 5m -c 150 <ALB_URL>/api/produk
   ```

3. Yang akan terekam (±6-8 menit):
   - CPU service naik melewati target 60%
   - Alarm target tracking berbunyi (±1-2 menit setelah CPU naik)
   - Task baru muncul: 2 → 3 → 4... (scale-out cooldown 60 detik)
   - Badge `handledBy` makin bervariasi
   - Setelah `hey` selesai: CPU turun, dan beberapa menit kemudian
     task kembali ke 2 (scale-in)

4. Potong video jadi ±90 detik (percepat bagian menunggu 4-8x).

### Narasi saat memutar video

> "Ini saya rekam kemarin karena prosesnya beberapa menit. Yang kalian lihat: traffic naik, CPU melewati 60%, dan TANPA SAYA MENYENTUH APA PUN — sistem menambah kapasitasnya sendiri. Lalu saat traffic turun, dia mengecil lagi sendiri. Bayar hanya untuk yang dipakai."

---

## Penutup — narasi kunci (hafalkan)

> "Satu hal terakhir, dan ini yang paling penting dari seluruh sesi ini.
>
> Aplikasi Go dan Svelte yang barusan jalan di ECS Fargate, dengan Aurora, auto-scaling, multi-AZ — itu **kode yang sama persis** dengan yang jalan di server Docker seharga seratus ribu rupiah tadi. Tidak ada satu baris pun yang berubah. Silakan cek repo-nya — folder demo-3 bahkan tidak punya folder source code; dia menunjuk ke source demo-2.
>
> Yang berubah hanya konfigurasi deploy-nya. Karena aplikasi ini ditulis dengan prinsip cloud-native sejak awal — config dari environment, stateless, punya health check, graceful shutdown — dia bisa jalan di mana saja: laptop kalian, VPS, Kubernetes, AWS.
>
> Jadi kalau kalian tanya 'mulai belajar cloud dari mana?' — jawabannya bukan menghafal 200 service AWS. Mulailah dari **menulis aplikasi yang siap untuk cloud**. Sisanya urusan konfigurasi."

---

## Perintah darurat

| Situasi | Perintah |
|---|---|
| Cek kondisi service | `make status` / `make events` |
| Task tidak mau naik | `make events` — baca pesan error (biasanya image/secret) |
| ALB 503 | target group kosong — cek `make tasks`, tunggu health check |
| Console logout di panggung | pakai video fallback momen A |
| Semua gagal total | video fallback SEMUA momen sudah ada (H-1) |

## ⚠️ SETELAH ACARA — WAJIB

```bash
make destroy   # = terraform destroy — hentikan ALB + Aurora + Fargate
```

Lalu verifikasi di Billing console besoknya: tidak ada biaya berjalan.
