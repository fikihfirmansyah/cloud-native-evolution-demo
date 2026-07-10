#!/usr/bin/env bash
# =============================================================
# Deploy "jadul" — pola yang masih dipakai banyak perusahaan:
# SSH ke server, tarik kode baru, replace file DI TEMPAT,
# restart service.
#
# PERHATIKAN: TIDAK ADA mekanisme zero-downtime di sini.
# Selama composer install + restart php-fpm berjalan (bisa
# 10-30 detik), situs melempar error ke pengunjung.
# Itu BUKAN bug skrip ini — itulah poin demonya.
#
# Jalankan di VPS: bash /var/www/cloud-native-evolution-demo/demo-1-legacy/deploy-jadul.sh
# =============================================================
set -euo pipefail

APP_DIR="/var/www/cloud-native-evolution-demo/demo-1-legacy"
cd "$APP_DIR"

echo "==> [1/5] git pull (kode baru menimpa kode lama, di server yang sama)"
git pull

echo "==> [2/5] composer install (autoloader dibongkar-pasang — di sinilah request mulai error)"
composer install --no-dev --optimize-autoloader --no-interaction

echo "==> [3/5] migrate database"
php artisan migrate --force

echo "==> [4/5] rebuild config cache"
php artisan config:cache

echo "==> [5/5] restart php-fpm (semua request yang sedang jalan terputus)"
systemctl restart php8.3-fpm

echo "==> Deploy selesai. (Berapa detik downtime tadi? Cek loop curl-mu.)"
