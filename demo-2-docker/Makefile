# =============================================================
# Shortcut perintah demo — mengetik perintah panjang di panggung
# itu rawan typo. Cukup: make watch, make kill-one, make scale-5
#
# Semua target membaca .env (DOMAIN_API dll).
# =============================================================

# Muat .env kalau ada
ifneq (,$(wildcard .env))
include .env
export
endif

.PHONY: help up down build ps logs watch kill-one scale-2 scale-3 scale-5 rollout seed-check reset

help: ## Tampilkan daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Start seluruh stack (build lokal kalau image belum ada)
	docker compose up -d --scale api=3

down: ## Stop seluruh stack (data postgres tetap aman di volume)
	docker compose down

build: ## Build ulang image secara lokal
	docker compose -f docker-compose.yml -f docker-compose.dev.yml build

ps: ## Status container
	docker compose ps

logs: ## Ikuti log api
	docker compose logs -f api

watch: ## Loop curl health — tampilkan handledBy + version per baris (untuk proyektor)
	./scripts/watch.sh

kill-one: ## DEMO self-healing: bunuh satu replica api secara acak
	@VICTIM=$$(docker compose ps -q api | shuf -n 1); \
	echo "💀 Membunuh container: $$(docker inspect --format '{{.Name}}' $$VICTIM)"; \
	docker kill $$VICTIM

scale-2: ## Scale api ke 2 replica
	docker compose up -d --no-recreate --scale api=2 api

scale-3: ## Scale api ke 3 replica (default demo)
	docker compose up -d --no-recreate --scale api=3 api

scale-5: ## DEMO scaling: scale api ke 5 replica
	docker compose up -d --no-recreate --scale api=5 api

rollout: ## Rolling deploy manual tanpa downtime (alternatif webhook Portainer)
	./scripts/rollout.sh

seed-check: ## Cek isi tabel produk di postgres
	docker compose exec postgres psql -U produk -d katalog -c "SELECT id, nama, harga, stok FROM produk;"

reset: ## Reset total: hapus container + volume, lalu start ulang (seed ulang otomatis)
	docker compose down -v
	docker compose up -d --scale api=3
