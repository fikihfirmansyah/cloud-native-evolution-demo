# =============================================================
# ECR + ECS Fargate — tempat aplikasi Go (kode demo-2) berjalan.
#
# 💰 Fargate: 0.25 vCPU + 0.5 GB ≈ $0.014/jam per task →
#    2 task ≈ $0.7/hari.
# =============================================================

# ---------- ECR: registry image ----------
resource "aws_ecr_repository" "api" {
  name         = "${var.project}-api"
  force_delete = true # demo: hapus repo beserta image saat destroy

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------- Log group ----------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project}-api"
  retention_in_days = 7
}

# ---------- IAM ----------
# Execution role: dipakai AGEN ECS untuk pull image, tulis log,
# dan mengambil secret SEBELUM container jalan.
resource "aws_iam_role" "execution" {
  name_prefix = "${var.project}-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name_prefix = "secrets-"
  role        = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.database_url.arn
    }]
  })
}

# Task role: identitas APLIKASI saat runtime. Aplikasi kita tidak
# memanggil API AWS apa pun → role kosong (least privilege).
resource "aws_iam_role" "task" {
  name_prefix = "${var.project}-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ---------- Cluster ----------
resource "aws_ecs_cluster" "utama" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # metrics detail untuk video auto-scaling
  }
}

# ---------- Task definition ----------
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = "api"
    image     = "${aws_ecr_repository.api.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    # DATABASE_URL di-inject dari Secrets Manager — aplikasi
    # menerimanya sebagai env var biasa, sama seperti di demo-2.
    secrets = [{
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.database_url.arn
    }]

    # VERSION sudah dibake ke image saat build (build arg dari CI),
    # jadi tidak perlu di-set di sini. PORT default 8080.

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "api"
      }
    }
  }])
}

# ---------- Service ----------
resource "aws_ecs_service" "api" {
  name            = "${var.project}-api"
  cluster         = aws_ecs_cluster.utama.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_min_count
  launch_type     = "FARGATE"

  # Rolling deploy: naikkan task baru dulu (sampai 200%), baru
  # matikan yang lama — tidak pernah di bawah 100% kapasitas.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true # public subnet tanpa NAT — lihat komentar di vpc.tf
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }

  # Tunggu ALB siap sebelum service dibuat
  depends_on = [aws_lb_listener.http]

  # CI melakukan force-new-deployment; desired_count juga diubah
  # live saat demo — jangan sampai terraform me-reset-nya.
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ---------- Auto scaling ----------
resource "aws_appautoscaling_target" "api" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.utama.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.api_min_count
  max_capacity       = var.api_max_count
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.project}-api-cpu-60"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.api.service_namespace
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60 # jaga rata-rata CPU service di 60%

    # Dipercepat untuk demo/video (default 300/300 detik terlalu
    # santai untuk direkam).
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
  }
}
