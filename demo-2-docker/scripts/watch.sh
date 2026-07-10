#!/usr/bin/env bash
# =============================================================
# Loop curl yang enak dilihat di proyektor.
# Tiap baris: timestamp | handledBy | version — atau FAIL merah.
#
# Pakai: ./scripts/watch.sh            (baca DOMAIN_API dari .env)
#        ./scripts/watch.sh http://localhost:8080   (override URL)
# =============================================================
set -u

# Muat .env kalau ada (untuk DOMAIN_API)
if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  source "$(dirname "$0")/../.env"
fi

BASE_URL="${1:-https://${DOMAIN_API:?set DOMAIN_API di .env atau beri argumen URL}}"

HIJAU='\033[0;32m'
BIRU='\033[0;34m'
MERAH='\033[0;31m'
RESET='\033[0m'

echo "Watching ${BASE_URL}/api/health — Ctrl+C untuk berhenti"
echo "---------------------------------------------------------"

while true; do
  TS=$(date '+%H:%M:%S')
  RESP=$(curl -s --max-time 2 "${BASE_URL}/api/health" 2>/dev/null)
  if [ -n "$RESP" ]; then
    HANDLED=$(echo "$RESP" | grep -o '"handledBy":"[^"]*"' | cut -d'"' -f4)
    VER=$(echo "$RESP" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    printf "%s  ${BIRU}instance=%-14s${RESET}  ${HIJAU}version=%s${RESET}\n" "$TS" "$HANDLED" "$VER"
  else
    printf "%s  ${MERAH}✗ FAIL — tidak ada respons${RESET}\n" "$TS"
  fi
  sleep 0.5
done
