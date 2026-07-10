# =============================================================
# Frontend statis — S3 (private) + CloudFront (OAC).
#
# Hasil build Svelte YANG SAMA dengan demo-2 di-sync ke S3 oleh
# CI; CloudFront menyajikannya dari edge. Bucket tetap private —
# hanya CloudFront yang boleh membaca (Origin Access Control).
#
# 💰 Biaya: S3 + CloudFront untuk demo ≈ nol koma sekian dolar.
# =============================================================

resource "aws_s3_bucket" "web" {
  bucket_prefix = "${var.project}-web-"
  force_destroy = true # demo: destroy langsung hapus isi bucket
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "web" {
  name                              = "${var.project}-web-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project} frontend"
  price_class         = "PriceClass_200" # termasuk edge Asia (Jakarta/Singapura)

  origin {
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id                = "s3-web"
    origin_access_control_id = aws_cloudfront_origin_access_control.web.id
  }

  # Origin kedua: ALB. CloudFront meneruskan /api/* ke ALB sehingga
  # frontend memanggil API same-origin (https CloudFront) — tidak ada
  # masalah mixed-content http/https, tidak perlu cert di ALB.
  origin {
    domain_name = aws_lb.api.dns_name
    origin_id   = "alb-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # CloudFront→ALB internal AWS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # /api/* → ALB, tanpa cache (data dinamis)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    # Managed policies (ID baku AWS):
    # CachingDisabled + AllViewerExceptHostHeader
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  default_cache_behavior {
    target_origin_id       = "s3-web"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Managed policy "CachingOptimized" (ID baku dari AWS)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # SPA: akses path apa pun → index.html (S3 private melempar 403)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # pakai domain *.cloudfront.net
  }
}

# Bucket policy: hanya CloudFront distribution INI yang boleh baca.
resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.web.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.web.arn
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.web]
}
