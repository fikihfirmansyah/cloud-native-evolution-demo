# =============================================================
# Shortcut demo-3 — dijalankan dari laptop dengan AWS CLI
# terkonfigurasi (profile/creds region ap-southeast-1).
#
# Nilai CLUSTER/SERVICE/URL diambil otomatis dari terraform output.
# =============================================================

TF_DIR   := terraform
REGION   := ap-southeast-1
CLUSTER  = $(shell cd $(TF_DIR) && terraform output -raw ecs_cluster_name)
SERVICE  = $(shell cd $(TF_DIR) && terraform output -raw ecs_service_name)
ALB_URL  = $(shell cd $(TF_DIR) && terraform output -raw alb_url)

.PHONY: help apply destroy outputs seed watch status tasks scale-4 scale-2 load events

help: ## Daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

apply: ## terraform apply (⚠️ mulai biaya per jam!)
	cd $(TF_DIR) && terraform init && terraform apply

destroy: ## ⚠️ WAJIB setelah acara — hentikan semua biaya
	cd $(TF_DIR) && terraform destroy

outputs: ## Tampilkan semua terraform output (untuk isi GitHub variables)
	cd $(TF_DIR) && terraform output

seed: ## Jalankan task seed database (lihat seed-aurora.md)
	@cd $(TF_DIR) && eval "$$(terraform output -raw seed_command)"

watch: ## Loop curl health ALB — tampilkan handledBy + version (untuk proyektor)
	../demo-2-docker/scripts/watch.sh $(ALB_URL)

status: ## Ringkasan service: running/desired + rollout state
	aws ecs describe-services --cluster $(CLUSTER) --services $(SERVICE) --region $(REGION) \
	  --query 'services[0].{desired:desiredCount,running:runningCount,rollout:deployments[0].rolloutState}' --output table

tasks: ## Daftar task yang berjalan
	aws ecs list-tasks --cluster $(CLUSTER) --service-name $(SERVICE) --region $(REGION) --output table

scale-4: ## DEMO: naikkan desired count ke 4 (live di panggung)
	aws ecs update-service --cluster $(CLUSTER) --service $(SERVICE) --desired-count 4 --region $(REGION) --query 'service.desiredCount'

scale-2: ## Kembalikan desired count ke 2
	aws ecs update-service --cluster $(CLUSTER) --service $(SERVICE) --desired-count 2 --region $(REGION) --query 'service.desiredCount'

load: ## Load test untuk memancing auto scaling (untuk rekaman H-1)
	hey -z 5m -c 150 $(ALB_URL)/api/produk

events: ## 10 event terakhir service (lihat proses scaling/deploy)
	aws ecs describe-services --cluster $(CLUSTER) --services $(SERVICE) --region $(REGION) \
	  --query 'services[0].events[:10].[createdAt,message]' --output table
