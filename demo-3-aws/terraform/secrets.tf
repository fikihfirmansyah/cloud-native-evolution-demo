# =============================================================
# Secrets Manager — DATABASE_URL lengkap sebagai satu secret.
#
# Aplikasi Go (kode demo-2, tanpa modifikasi!) hanya tahu satu
# hal: "baca env DATABASE_URL". Ia tidak peduli nilai itu datang
# dari file .env di laptop, dari docker-compose, atau dari
# Secrets Manager yang di-inject ECS. Itulah inti 12-factor.
#
# 💰 Biaya: $0.40/bulan per secret + $0.05 per 10k API call — receh.
# =============================================================

resource "aws_secretsmanager_secret" "database_url" {
  name_prefix = "${var.project}-database-url-"

  # Demo: hapus langsung saat destroy (default 30 hari recovery
  # window membuat nama secret "nyangkut" kalau apply ulang).
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id

  # Format sama persis dengan DATABASE_URL di demo-2
  secret_string = "postgres://${var.db_username}:${random_password.db.result}@${aws_rds_cluster.aurora.endpoint}:5432/${var.db_name}?sslmode=require"
}
