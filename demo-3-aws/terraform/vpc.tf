# =============================================================
# VPC 2 Availability Zone — public + private subnet.
#
# Layout:
#   public subnet  : ALB + task ECS Fargate
#   private subnet : Aurora (tidak bisa diakses dari internet)
#
# KEPUTUSAN BIAYA: task ECS ditaruh di PUBLIC subnet dengan
# public IP (tetap terkunci security group — hanya ALB yang bisa
# masuk). Alternatif "textbook" adalah private subnet + NAT
# Gateway, tapi NAT ≈ $0.06/jam + biaya per GB ≈ $45/bulan —
# tidak sepadan untuk demo. Sebutkan trade-off ini di presentasi
# kalau ada yang bertanya.
# =============================================================

data "aws_availability_zones" "ini" {
  state = "available"
}

resource "aws_vpc" "utama" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.utama.id

  tags = { Name = "${var.project}-igw" }
}

# ---------- Public subnets (ALB + ECS) ----------
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.utama.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index) # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.ini.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-public-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.utama.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Private subnets (Aurora) ----------
# Tanpa route ke internet sama sekali — database terisolasi penuh.
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.utama.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10 + count.index) # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = data.aws_availability_zones.ini.names[count.index]

  tags = { Name = "${var.project}-private-${count.index}" }
}

# =============================================================
# Security groups — rantai akses yang BENAR:
#   internet → ALB (:80) → ECS (:8080) → Aurora (:5432)
# Tiap lapis hanya menerima traffic dari lapis sebelumnya.
# =============================================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project}-alb-"
  description = "ALB: terima HTTP/HTTPS dari internet"
  vpc_id      = aws_vpc.utama.id

  ingress {
    description = "HTTP dari mana saja"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS dari mana saja"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project}-ecs-"
  description = "Task ECS: hanya terima traffic dari ALB"
  vpc_id      = aws_vpc.utama.id

  ingress {
    description     = "Port container, HANYA dari ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress bebas: pull image ECR + ambil secret + kirim log
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "aurora" {
  name_prefix = "${var.project}-aurora-"
  description = "Aurora: hanya terima koneksi dari task ECS"
  vpc_id      = aws_vpc.utama.id

  ingress {
    description     = "PostgreSQL, HANYA dari ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
}
