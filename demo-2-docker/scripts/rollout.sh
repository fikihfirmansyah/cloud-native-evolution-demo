#!/usr/bin/env bash
# =============================================================
# Rolling deploy manual TANPA downtime untuk service "api".
#
# Cara kerja (teknik "scale up lalu turunkan yang lama"):
#   1. Pull image terbaru
#   2. Start replica BARU di samping yang lama (scale 2x)
#   3. Tunggu replica baru healthy
#   4. Matikan replica lama satu per satu (Traefik otomatis
#      berhenti mengirim traffic ke container yang hilang)
#
# Ini alternatif kalau redeploy via Portainer webhook menimbulkan
# blip — dipakai lewat: make rollout
# =============================================================
set -euo pipefail

SERVICE="api"
REPLICAS="${REPLICAS:-3}"

cd "$(dirname "$0")/.."

echo "==> 1/4 Pull image terbaru..."
docker compose pull "$SERVICE"

# Catat container lama SEBELUM scale up
OLD_CONTAINERS=$(docker compose ps -q "$SERVICE")
OLD_COUNT=$(echo "$OLD_CONTAINERS" | grep -c . || true)
echo "==> Container lama: ${OLD_COUNT}"

echo "==> 2/4 Start ${REPLICAS} replica baru di samping yang lama..."
docker compose up -d --no-deps --no-recreate --scale "$SERVICE"=$((OLD_COUNT + REPLICAS)) "$SERVICE"

echo "==> 3/4 Menunggu replica baru healthy..."
NEW_CONTAINERS=$(docker compose ps -q "$SERVICE" | grep -v -F "$OLD_CONTAINERS" || true)
for c in $NEW_CONTAINERS; do
  for i in $(seq 1 30); do
    STATUS=$(docker inspect --format '{{.State.Health.Status}}' "$c" 2>/dev/null || echo "unknown")
    if [ "$STATUS" = "healthy" ]; then
      echo "    ✓ $(docker inspect --format '{{.Name}}' "$c") healthy"
      break
    fi
    if [ "$i" = 30 ]; then
      echo "    ✗ container $c tidak kunjung healthy — batalkan rollout" >&2
      exit 1
    fi
    sleep 2
  done
done

echo "==> 4/4 Matikan replica lama satu per satu..."
for c in $OLD_CONTAINERS; do
  # SIGTERM → graceful shutdown di Go menyelesaikan request berjalan
  docker stop -t 15 "$c" >/dev/null
  docker rm "$c" >/dev/null
  echo "    ✓ replica lama dimatikan"
  sleep 1
done

echo "==> Selesai. Replica aktif:"
docker compose ps "$SERVICE"
