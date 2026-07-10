# Skrip Demo 1 — Legacy (Laravel di VPS, deploy jadul)

> Persiapan sebelum naik panggung:
> - VPS hidup, situs jalan: `make status` → semua `active`
> - `.env.demo` terisi (VPS + URL), SSH key ter-load (`ssh-add`)
> - Browser tab: halaman katalog `http://<domain>`
> - Terminal 1 (font besar): siap `make watch`
> - Terminal 2: untuk perintah demo
> - `hey` terinstall di laptop (momen C)

**Narasi pembuka demo:**

> "Ini aplikasi Laravel di satu VPS — nginx, PHP, MySQL, semuanya numpuk di satu server. Jujur saja: beginilah cara sebagian besar aplikasi di Indonesia di-deploy hari ini. Dan itu bukan aib — ini titik awal kita semua. Mari kita lihat apa masalahnya."

---

## Momen A — Deploy = Downtime

**Langkah:**

1. Terminal 1:

   ```bash
   make watch
   ```

   > "Loop ini menembak API setiap detik. Hijau artinya hidup. Ingat warna itu."

2. Ubah sesuatu yang terlihat (mis. judul di `resources/views/produk.blade.php`), commit, push. Atau langsung tanpa git:

   ```bash
   make deploy
   ```

   (Kalau lewat git push, tunjukkan tab GitHub Actions dulu:)

   > "Kelihatan modern kan? Ada CI/CD, ada GitHub Actions. Tapi perhatikan apa yang sebenarnya dilakukan pipeline ini: SSH ke server, git pull, restart. Sama seperti yang kita lakukan manual sepuluh tahun lalu — cuma sekarang robotnya yang mengetik."

3. Tunjuk Terminal 1 saat deploy jalan:

   > "Merah. Lihat itu — HTTP 500, HTTP 502. Setiap kali kami deploy, pengunjung yang sedang buka situs dapat halaman error. Kalau deploy-nya jam 2 siang dan ada 100 pengunjung aktif... ya sudah, 100 orang lihat error. Makanya perusahaan dengan pola ini selalu deploy jam 2 **malam**."

**Pemulihan:** otomatis — begitu deploy selesai, loop hijau lagi. Verifikasi: browser refresh, perubahan tampil.

---

## Momen B — Database mati = semuanya mati

**Narasi:**

> "Sekarang skenario horor kedua. Anggap MySQL crash — kehabisan memori, disk penuh, apa pun. Di server 2 GB yang isinya nginx + PHP + MySQL sekaligus, itu bukan 'kalau', tapi 'kapan'."

**Langkah:**

1. Terminal 2:

   ```bash
   make stop-mysql
   ```

2. Tunjuk Terminal 1 — merah semua. Refresh browser — error 500:

   > "Situs mati total. Dan yang paling penting: **tidak ada yang tahu**. Tidak ada health check, tidak ada alarm, tidak ada auto-restart. Aplikasi ini baru hidup lagi kalau ada manusia yang sadar, SSH ke server, dan menyalakan MySQL — mungkin setelah pelanggan komplain di media sosial."

3. Pemulihan (lakukan sambil bicara):

   ```bash
   make start-mysql
   ```

   > "Saya barusan jadi 'monitoring system'-nya. Manusia sebagai health check — mahal dan lambat."

**Pemulihan:** `make start-mysql` → loop hijau dalam 1-2 detik.

---

## Momen C — Traffic naik = keteteran

**Narasi:**

> "Skenario ketiga: aplikasi kalian viral. Traffic naik 10x. Apa yang terjadi?"

**Langkah:**

1. Terminal 2 (biarkan Terminal 1 tetap watch):

   ```bash
   make load
   # = hey -z 20s -c 100 http://<domain>/api/produk
   ```

2. Sambil hey jalan, tunjuk Terminal 1 — respons melambat / mulai merah:

   > "100 koneksi paralel — bukan angka besar untuk aplikasi viral — dan server 2 CPU ini langsung ngos-ngosan. PHP-FPM kehabisan worker, antrean menumpuk, sebagian request time-out."

3. Setelah hey selesai, bacakan hasilnya (requests/sec, latensi p99, jumlah error):

   > "Solusi di dunia legacy? Beli server lebih besar, migrasi manual malam-malam, dan berdoa. Tidak ada tombol 'tambah kapasitas'. Nanti di demo berikutnya, tombol itu ada — dan namanya satu baris perintah."

**Pemulihan:** tidak perlu — beban berhenti sendiri setelah 20 detik. Kalau php-fpm masih lemas: `ssh` lalu `systemctl restart php8.3-fpm`.

---

## Perintah darurat

| Situasi | Perintah |
|---|---|
| Cek semua service | `make status` |
| Situs masih 500 setelah momen B | `make start-mysql`, lalu `make status` |
| php-fpm hang setelah load test | `ssh $(VPS)` → `systemctl restart php8.3-fpm` |
| Deploy rusak parah | SSH → `cd /var/www/cloud-native-evolution-demo && git reset --hard HEAD~1 && bash demo-1-legacy/deploy-jadul.sh` |
| VPS tidak bisa diakses | pakai video fallback — jangan debug di panggung |
