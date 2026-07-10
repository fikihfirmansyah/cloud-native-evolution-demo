output "alb_url" {
  description = "URL ALB mentah (HTTP) — untuk curl/debug"
  value       = "http://${aws_lb.api.dns_name}"
}

output "api_url" {
  description = "URL API publik (domain kustom)"
  value       = var.enable_https ? "https://${var.domain_api}" : "http://${var.domain_api}"
}

output "frontend_url" {
  description = "URL frontend publik (domain kustom)"
  value       = var.enable_cloudfront ? "https://${var.domain_web}" : "http://${var.domain_web}"
}

output "cloudfront_url" {
  description = "URL CloudFront bawaan (*.cloudfront.net) — kosong jika fallback S3"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.web[0].domain_name}" : ""
}

output "s3_website_url" {
  description = "URL S3 website — hanya saat enable_cloudfront = false"
  value       = var.enable_cloudfront ? "" : "http://${aws_s3_bucket_website_configuration.web[0].website_endpoint}"
}

output "vite_api_base" {
  description = "Nilai VITE_API_BASE saat build frontend (kosong = same-origin CloudFront)"
  value       = var.enable_cloudfront ? "" : (var.enable_https ? "https://${var.domain_api}" : "http://${var.domain_api}")
}

output "ecr_repository_url" {
  description = "Repo ECR untuk push image API"
  value       = aws_ecr_repository.api.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.utama.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}

output "s3_bucket_web" {
  description = "Bucket tujuan sync hasil build Svelte"
  value       = aws_s3_bucket.web.id
}

output "cloudfront_distribution_id" {
  description = "Untuk invalidation setelah sync frontend — kosong jika fallback S3"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.web[0].id : ""
}

output "acm_validation_dns" {
  description = "Record CNAME validasi ACM — tambahkan di DNS sebelum HTTPS/CloudFront aktif"
  value = merge(
    {
      for dvo in aws_acm_certificate.api.domain_validation_options : "api-${dvo.domain_name}" => {
        name  = dvo.resource_record_name
        type  = dvo.resource_record_type
        value = dvo.resource_record_value
      }
    },
    var.enable_cloudfront ? {
      for dvo in aws_acm_certificate.web[0].domain_validation_options : "web-${dvo.domain_name}" => {
        name  = dvo.resource_record_name
        type  = dvo.resource_record_type
        value = dvo.resource_record_value
      }
    } : {}
  )
}

output "dns_setup" {
  description = "Ringkasan record DNS yang perlu ditambahkan"
  value = var.enable_cloudfront ? {
    api_cname  = "${var.domain_api} → ${aws_lb.api.dns_name}"
    web_cname  = "${var.domain_web} → ${aws_cloudfront_distribution.web[0].domain_name}"
    acm_api    = "Lihat acm_validation_dns (api-*)"
    acm_web    = "Lihat acm_validation_dns (web-*)"
  } : {
    api_cname = "${var.domain_api} → ${aws_lb.api.dns_name}"
    web_cname = "${var.domain_web} → ${aws_s3_bucket_website_configuration.web[0].website_endpoint}"
    acm_api   = "Lihat acm_validation_dns (api-*)"
    note      = "Set enable_cloudfront=true setelah akun AWS terverifikasi, lalu apply ulang"
  }
}

output "seed_command" {
  description = "Perintah menjalankan task seed database (one-off)"
  value       = <<-EOT
    aws ecs run-task \
      --region ${var.aws_region} \
      --cluster ${aws_ecs_cluster.utama.name} \
      --task-definition ${aws_ecs_task_definition.seed.family} \
      --launch-type FARGATE \
      --network-configuration 'awsvpcConfiguration={subnets=[${aws_subnet.public[0].id}],securityGroups=[${aws_security_group.ecs.id}],assignPublicIp=ENABLED}'
  EOT
}
