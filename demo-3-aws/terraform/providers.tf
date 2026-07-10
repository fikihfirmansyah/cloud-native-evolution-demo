# =============================================================
# Demo 3 — Infrastruktur AWS sebagai kode (Terraform).
#
# ⚠️⚠️⚠️ PENTING — BIAYA ⚠️⚠️⚠️
# Stack ini menyalakan resource BERBAYAR PER JAM:
#   ALB + Aurora + Fargate ≈ $2-3 per hari.
# Apply H-1 sebelum acara, dan JANGAN LUPA:
#
#     terraform destroy
#
# SEGERA SETELAH ACARA SELESAI. Aurora dan ALB tidak punya
# tombol "pause" — selama ada, selama itu pula dibayar.
# =============================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "cloud-native-evolution-demo"
      Demo      = "demo-3-aws"
      ManagedBy = "terraform"
    }
  }
}

# CloudFront custom domain membutuhkan ACM di us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "cloud-native-evolution-demo"
      Demo      = "demo-3-aws"
      ManagedBy = "terraform"
    }
  }
}
