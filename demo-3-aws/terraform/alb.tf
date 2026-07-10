# =============================================================
# Application Load Balancer — pintu masuk API.
#
# 💰 Estimasi: ±$0.025/jam + LCU ≈ $0.6-1/hari. Komponen
#    "diam-diam mahal" — pastikan ikut ter-destroy!
#
# HTTP saja (tanpa cert/domain) — cukup untuk demo; URL ALB
# dipakai langsung. Kalau mau HTTPS: ACM cert + listener 443.
# =============================================================

resource "aws_lb" "api" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project}-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.utama.id
  target_type = "ip" # Fargate = awsvpc networking = target berupa IP task

  # Task yang sedang shutdown dikeluarkan dari rotasi dalam 15 detik
  # (default 300 — terlalu lama untuk demo rolling deploy).
  deregistration_delay = 15

  # Health check ke endpoint yang SAMA dengan healthcheck Docker
  # di demo-2 — satu endpoint, dipahami semua platform.
  health_check {
    path                = "/api/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
