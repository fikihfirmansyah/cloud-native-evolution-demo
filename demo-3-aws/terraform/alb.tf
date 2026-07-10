# =============================================================
# Application Load Balancer — pintu masuk API.
#
# 💰 Estimasi: ±$0.025/jam + LCU ≈ $0.6-1/hari.
#
# :80  → forward ke ECS (origin CloudFront memakai HTTP internal)
# :443 → HTTPS untuk domain API kustom (api-demo-aws-3...)
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
  target_type = "ip"

  deregistration_delay = 15

  health_check {
    path                = "/api/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# HTTP — tetap dibuka untuk origin CloudFront (http-only ke ALB).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# HTTPS — aktif setelah enable_https=true dan ACM tervalidasi.
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.api[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
