# Skrip Demo 2 — Docker + Traefik + Portainer

> Persiapan sebelum naik panggung:
> - Stack sudah jalan: `make up` (3 replica api), cek `make ps` semua healthy
> - Browser tab 1: `https://demo.example.com` (halaman produk + badge)
> - Browser tab 2: Portainer (halaman Containers)
> - Terminal 1 (besar, font besar): siap menjalankan `make watch`
> - Terminal 2: untuk perintah demo

---

## Momen A — Zero-Downtime Deploy

**Narasi pembuka:**

> "Tadi di demo pertama, setiap deploy berarti aplikasi mati beberapa detik. Sekarang lihat apa yang terjadi kalau aplikasinya dibungkus container dan di-deploy dengan benar."

**Langkah:**

1. Terminal 1 — jalankan loop (biarkan jalan terus sepanjang demo):

   ```bash
   make watch
   ```

   > "Perhatikan: setiap setengah detik saya tembak API-nya. Setiap baris menunjukkan instance mana yang menjawab, dan versi aplikasinya."

2. Buka editor, ubah satu hal kecil yang terlihat — misal judul di `web/src/App.svelte` atau tambah emoji. Lalu:

   ```bash
   git add -A && git commit -m "demo: ubah judul" && git push
   ```

   > "Saya push ke GitHub. Sekarang GitHub Actions membangun image baru, push ke registry, lalu memberi tahu Portainer: 'tolong tarik versi baru'."

3. Tunjukkan tab Actions di GitHub (job berjalan). Sambil menunggu (±2-3 menit), jelaskan diagram: push → build image → GHCR → webhook → Portainer pull & recreate.

4. Saat deploy terjadi, tunjuk Terminal 1:

   > "Lihat kolom version — barusan berubah dari versi lama ke SHA commit baru. Dan lihat: **tidak ada satu baris FAIL pun**. Loop ini tidak pernah berhenti mendapat jawaban. Padahal barusan seluruh aplikasi diganti dengan versi baru. Itu zero-downtime deploy."

5. Tunjuk browser tab 1: badge hijau `version` sudah menunjukkan SHA baru.

**Pemulihan:** tidak perlu — stack sudah dalam kondisi baru yang sehat.

**Fallback kalau ada 1-2 baris FAIL:** jangan panik, jadikan bahan:
> "Ada satu-dua request yang kena blip — di setup produksi ini dihaluskan dengan rolling deploy penuh, yang akan kita lihat di demo AWS."
(Atau pakai `make rollout` yang benar-benar rolling.)

---

## Momen B — Self-Healing

**Narasi:**

> "Di demo pertama, kalau proses PHP-nya mati, situs mati sampai ada manusia yang SSH dan menyalakannya lagi. Sekarang saya akan membunuh salah satu container secara paksa. Live. Di depan kalian."

**Langkah:**

1. Pastikan Terminal 1 masih `make watch`.
2. Terminal 2:

   ```bash
   make kill-one
   ```

3. Tunjuk Terminal 1:

   > "Loop tetap jalan. Tidak ada FAIL. Yang berubah cuma satu: nilai `instance` — request sekarang dilayani replica lain. Traefik tahu ada container yang hilang dan langsung berhenti mengirim traffic ke sana."

4. Buka Portainer (tab 2), refresh:

   > "Dan lihat di Portainer — container yang saya bunuh sudah dinyalakan ulang otomatis oleh Docker, karena kita bilang `restart: unless-stopped`. Tidak ada manusia yang SSH. Tidak ada panik. Sistem menyembuhkan dirinya sendiri."

**Pemulihan:** otomatis. Verifikasi: `make ps` — semua replica Up (healthy).

---

## Momen C — Scaling

**Narasi:**

> "Server keteteran karena traffic naik? Di demo pertama solusinya: beli server lebih besar, migrasi, downtime. Sekarang:"

**Langkah:**

1. Terminal 2:

   ```bash
   make scale-5
   ```

2. Tunjuk Terminal 1:

   > "Perhatikan kolom instance — sekarang ada lima nama berbeda yang bergantian menjawab. Saya baru saja menggandakan kapasitas aplikasi dengan satu perintah, tanpa mati sedetik pun."

3. Tunjuk browser tab 1: badge biru `handledBy` berganti-ganti tiap 2 detik.

4. (Opsional) Turunkan lagi:

   ```bash
   make scale-3
   ```

   > "Turun lagi juga semudah itu. Tapi ingat — ini semua masih SATU server. Kalau server fisiknya yang mati, semua replica ikut mati. Itulah kenapa ada demo ketiga."

**Pemulihan:** `make scale-3` (kembali ke kondisi default).

---

## Perintah darurat

| Situasi | Perintah |
|---|---|
| Stack rusak total | `make reset` (hapus semua + seed ulang) |
| Cek kondisi | `make ps` dan `make logs` |
| Data produk hilang | `make seed-check` untuk verifikasi, `make reset` kalau kosong |
| Portainer webhook gagal | deploy manual: `docker compose pull && make rollout` |
