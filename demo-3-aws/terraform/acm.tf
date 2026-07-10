# =============================================================
# ACM — sertifikat TLS untuk domain kustom.
#   API  : ap-southeast-1 (dipasang di ALB listener 443)
#   Web  : us-east-1     (wajib untuk CloudFront custom domain)
#
# Validasi DNS: tambahkan record CNAME dari output
# acm_validation_dns, lalu set enable_https = true dan apply ulang.
# =============================================================

resource "aws_acm_certificate" "api" {
  domain_name       = var.domain_api
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "api" {
  count = var.enable_https ? 1 : 0

  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.api.domain_validation_options : dvo.resource_record_name]

  timeouts {
    create = "15m"
  }
}

resource "aws_acm_certificate" "web" {
  count = var.enable_cloudfront ? 1 : 0

  provider = aws.us_east_1

  domain_name       = var.domain_web
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "web" {
  count = var.enable_cloudfront ? 1 : 0

  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.web[0].arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.web[0].domain_validation_options : dvo.resource_record_name]

  timeouts {
    create = "15m"
  }
}
