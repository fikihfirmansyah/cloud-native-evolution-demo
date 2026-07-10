#!/usr/bin/env bash
# =============================================================
# Setup VPS demo-1 (legacy) — Ubuntu 22.04, jalankan sebagai root.
#
# Idempotent: aman dijalankan ulang kalau gagal di tengah.
#
# Pakai:
#   sudo REPO_URL=https://github.com/user/cloud-native-evolution-demo.git \
#        DOMAIN=legacy.example.com \
#        bash setup-vps.sh
#
# Setelah selesai: http://<DOMAIN atau IP VPS>/ menampilkan katalog.
# =============================================================
set -euo pipefail

# ---------- Konfigurasi ----------
REPO_URL="${REPO_URL:?set REPO_URL=<url git repo>}"
DOMAIN="${DOMAIN:-_}"                      # "_" = terima semua host (akses via IP)
BASE_DIR="/var/www/cloud-native-evolution-demo"
APP_DIR="${BASE_DIR}/demo-1-legacy"        # app hidup di subfolder monorepo
DB_NAME="katalog"
DB_USER="katalog"
DB_PASS_FILE="/root/.katalog-db-pass"

export DEBIAN_FRONTEND=noninteractive

# ---------- 1. Paket dasar ----------
# PPA ondrej/php karena Ubuntu 22.04 bawaan hanya PHP 8.1,
# sedangkan Laravel 11 butuh PHP >= 8.2.
echo "==> 1/7 Install paket (nginx, PHP 8.3, MySQL, git)..."
apt-get update -q
apt-get install -y -q software-properties-common curl git unzip
add-apt-repository -y ppa:ondrej/php
apt-get update -q
apt-get install -y -q \
    nginx \
    mysql-server \
    php8.3-fpm php8.3-cli php8.3-mysql php8.3-xml php8.3-mbstring \
    php8.3-curl php8.3-zip php8.3-bcmath php8.3-intl

# ---------- 2. Composer ----------
echo "==> 2/7 Install composer..."
if ! command -v composer >/dev/null; then
    curl -fsS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin --filename=composer
fi

# ---------- 3. Database + user ----------
# Password digenerate sekali lalu disimpan di /root — jalankan ulang
# skrip tidak mengganti password (idempotent).
echo "==> 3/7 Setup MySQL database + user..."
if [ ! -f "$DB_PASS_FILE" ]; then
    openssl rand -hex 16 > "$DB_PASS_FILE"
    chmod 600 "$DB_PASS_FILE"
fi
DB_PASS="$(cat "$DB_PASS_FILE")"

mysql <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# ---------- 4. Clone repo (deploy pertama) ----------
echo "==> 4/7 Clone repo..."
if [ ! -d "$BASE_DIR/.git" ]; then
    git clone "$REPO_URL" "$BASE_DIR"
else
    echo "    repo sudah ada, skip clone"
fi

# ---------- 5. Setup aplikasi Laravel ----------
echo "==> 5/7 Setup Laravel (.env, composer, migrate, seed)..."
cd "$APP_DIR"
composer install --no-dev --optimize-autoloader --no-interaction

if [ ! -f .env ]; then
    cp .env.example .env
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env
    sed -i "s|^APP_URL=.*|APP_URL=http://${DOMAIN}|" .env
    php artisan key:generate --force
fi

php artisan migrate --force
php artisan db:seed --force
php artisan config:cache

# Permission: php-fpm (www-data) harus bisa tulis storage + cache.
# Session driver "file" berarti session user disimpan DI SINI —
# state nempel di disk server ini. Bagian dari cerita demo.
chown -R www-data:www-data "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

# ---------- 6. Nginx vhost ----------
echo "==> 6/7 Konfigurasi nginx..."
cat > /etc/nginx/sites-available/katalog-legacy <<NGINX
server {
    listen 80;
    server_name ${DOMAIN};

    root ${APP_DIR}/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/katalog-legacy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# ---------- 7. Restart service ----------
echo "==> 7/7 Restart service..."
systemctl enable --now php8.3-fpm nginx mysql
systemctl reload nginx
systemctl restart php8.3-fpm

echo ""
echo "============================================="
echo "Selesai! Buka: http://${DOMAIN}"
echo "Password DB tersimpan di: ${DB_PASS_FILE}"
echo "Deploy berikutnya: bash ${APP_DIR}/deploy-jadul.sh"
echo "============================================="
