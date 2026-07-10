# =============================================================
# Aurora Serverless v2 — PostgreSQL, min 0.5 / max 1 ACU.
#
# 💰 Estimasi biaya (ap-southeast-1): ±$0.12/ACU-jam →
#    0.5 ACU × 24 jam ≈ $1.5/hari + storage sen-senan.
#    Komponen TERMAHAL kedua setelah ALB kalau lupa destroy!
# =============================================================

resource "random_password" "db" {
  length = 32
  # Hanya alfanumerik supaya aman ditaruh di URL koneksi
  # (karakter seperti @ : / ? akan merusak format postgres://)
  special = false
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project}-aurora"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.project}-aurora"

  engine = "aurora-postgresql"
  # Cek versi yang tersedia di Singapura kalau apply gagal di sini:
  # aws rds describe-db-engine-versions --engine aurora-postgresql \
  #   --query 'DBEngineVersions[].EngineVersion' --region ap-southeast-1
  engine_version = "16.6"
  engine_mode    = "provisioned" # Serverless v2 = provisioned + scaling config

  database_name   = var.db_name
  master_username = var.db_username
  master_password = random_password.db.result

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1.0
  }

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  # Setting khusus DEMO — jangan tiru di produksi:
  skip_final_snapshot     = true # destroy tanpa snapshot (cepat, tanpa sisa biaya)
  apply_immediately       = true
  backup_retention_period = 1
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "${var.project}-aurora-1"
  cluster_identifier = aws_rds_cluster.aurora.id

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version
  instance_class = "db.serverless" # instance class khusus Serverless v2

  publicly_accessible = false
}
