# =============================================================
# Task one-off untuk seed database Aurora.
#
# Masalah: Aurora di private subnet, tidak bisa di-psql dari
# laptop. Solusi paling sederhana: task Fargate sekali-jalan
# berisi psql yang membaca SQL dari env var (isi file
# shared/seed-data.sql di-embed ke task definition oleh
# terraform — tidak perlu bastion, tidak perlu upload apa pun).
#
# Cara pakai: lihat output "seed_command" / demo-3-aws/seed-aurora.md
# =============================================================

resource "aws_ecs_task_definition" "seed" {
  family                   = "${var.project}-seed"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([{
    name      = "seed"
    image     = "public.ecr.aws/docker/library/postgres:16-alpine" # cuma butuh psql-nya
    essential = true

    # SQL di-embed langsung dari file bersama — sumber data yang
    # sama persis dengan demo-2.
    environment = [{
      name  = "SEED_SQL"
      value = file("${path.module}/../../shared/seed-data.sql")
    }]

    secrets = [{
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.database_url.arn
    }]

    command = ["sh", "-c", "psql \"$DATABASE_URL\" -c \"$SEED_SQL\" && echo SEED-BERHASIL"]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "seed"
      }
    }
  }])
}
