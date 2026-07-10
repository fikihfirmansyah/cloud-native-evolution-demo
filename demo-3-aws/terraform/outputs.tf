output "alb_url" {
  description = "URL API (dipakai juga sebagai VITE_API_BASE saat build frontend)"
  value       = "http://${aws_lb.api.dns_name}"
}

output "cloudfront_url" {
  description = "URL frontend"
  value       = "https://${aws_cloudfront_distribution.web.domain_name}"
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
  description = "Untuk invalidation setelah sync frontend"
  value       = aws_cloudfront_distribution.web.id
}

# Perintah seed siap-copas — jalankan sekali setelah apply.
# Detail + cara verifikasi: ../seed-aurora.md
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
