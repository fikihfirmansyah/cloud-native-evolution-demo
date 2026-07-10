# =============================================================
# Shortcut demo-1 — dijalankan dari LAPTOP (bukan di VPS).
# Semua aksi server lewat SSH.
#
# Konfigurasi: buat file .env.demo di folder ini berisi:
#   VPS=root@203.0.113.10
#   URL=http://legacy.example.com
# =============================================================

ifneq (,$(wildcard .env.demo))
include .env.demo
export
endif

VPS ?= root@GANTI_IP_VPS
URL ?= http://GANTI_DOMAIN

.PHONY: help watch deploy stop-mysql start-mysql load ssh status

help: ## Daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

watch: ## Loop curl — satu baris per detik: timestamp + HTTP status (untuk proyektor)
	@echo "Watching $(URL) — Ctrl+C untuk berhenti"; \
	while true; do \
		CODE=$$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 $(URL)/api/produk || echo "ERR"); \
		TS=$$(date '+%H:%M:%S'); \
		if [ "$$CODE" = "200" ]; then \
			printf "%s  \033[0;32mHTTP %s ✓\033[0m\n" "$$TS" "$$CODE"; \
		else \
			printf "%s  \033[0;31mHTTP %s ✗ DOWN\033[0m\n" "$$TS" "$$CODE"; \
		fi; \
		sleep 1; \
	done

deploy: ## DEMO momen A: jalankan deploy jadul via SSH (lihat downtime di watch)
	ssh $(VPS) 'sudo bash /var/www/cloud-native-evolution-demo/demo-1-legacy/deploy-jadul.sh'

stop-mysql: ## DEMO momen B: matikan MySQL → semua halaman 500
	ssh $(VPS) 'source /etc/katalog-legacy.env 2>/dev/null; sudo systemctl stop $${MYSQL_SERVICE:-mysql}'

start-mysql: ## Pemulihan momen B: nyalakan MySQL lagi
	ssh $(VPS) 'source /etc/katalog-legacy.env 2>/dev/null; sudo systemctl start $${MYSQL_SERVICE:-mysql}'

load: ## DEMO momen C: load test 20 detik, 100 koneksi (butuh `hey` di laptop)
	hey -z 20s -c 100 $(URL)/api/produk

ssh: ## SSH ke VPS
	ssh $(VPS)

status: ## Cek status service di VPS
	ssh $(VPS) 'source /etc/katalog-legacy.env 2>/dev/null; sudo systemctl is-active nginx $${PHP_FPM_SERVICE:-php8.3-fpm} $${MYSQL_SERVICE:-mysql}'
