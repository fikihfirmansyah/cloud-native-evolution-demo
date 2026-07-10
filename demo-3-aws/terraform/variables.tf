variable "aws_region" {
  description = "Region AWS — Singapura"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Prefix nama semua resource"
  type        = string
  default     = "demo3"
}

variable "vpc_cidr" {
  description = "CIDR VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Nama database (sama dengan demo-2)"
  type        = string
  default     = "katalog"
}

variable "db_username" {
  description = "User database (sama dengan demo-2)"
  type        = string
  default     = "produk"
}

variable "api_cpu" {
  description = "CPU task Fargate (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memori task Fargate (MB)"
  type        = number
  default     = 512
}

variable "api_min_count" {
  description = "Jumlah task minimum (dan desired awal)"
  type        = number
  default     = 2
}

variable "api_max_count" {
  description = "Jumlah task maksimum saat auto scaling"
  type        = number
  default     = 6
}

variable "domain_api" {
  description = "Domain publik API (CNAME → ALB)"
  type        = string
  default     = "api-demo-aws-3.fikihfirmansyah.my.id"
}

variable "domain_web" {
  description = "Domain publik frontend (CNAME → CloudFront atau S3 website)"
  type        = string
  default     = "demo-aws-3.fikihfirmansyah.my.id"
}

variable "enable_cloudfront" {
  description = "CloudFront untuk frontend. Set false jika akun AWS belum terverifikasi untuk CloudFront."
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "HTTPS listener di ALB. Set true setelah record validasi ACM api-* ditambahkan di DNS."
  type        = bool
  default     = false
}
