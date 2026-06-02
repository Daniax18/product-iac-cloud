terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 — le bucket doit exister avant (créé manuellement une fois par session AWS Academy)
  backend "s3" {
    bucket = "iac-terraform-state-bucket-midera-02"   # à adapter, voir étapes AWS Academy
    key    = "iac-app/terraform.tfstate"
    region = "us-east-1"
    # Pas de dynamodb lock : AWS Academy ne permet pas de créer des tables DynamoDB facilement
  }
}

provider "aws" {
  region = var.aws_region
  # Les credentials viennent des variables d'environnement injectées par le CD :
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
}

# ─── Data sources ────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# ─── Subnets publics (ALB + Bastion) ──────────────────────────────────────────

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-subnet-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-subnet-public-b"
  }
}

# ─── Subnets privés (EC2 app + RDS) ───────────────────────────────────────────

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.app_name}-subnet-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.app_name}-subnet-private-b"
  }
}

# ─── Route Table publique ─────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ─── Elastic IP pour le NAT Gateway ──────────────────────────────────────────

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-nat-eip"
  }
}

# ─── NAT Gateway ──────────────────────────────────────────────────────────────
# Placé dans le subnet public pour que les subnets privés puissent sortir vers internet

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.app_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# ─── Route Table privée ───────────────────────────────────────────────────────
# Les subnets privés sortent vers internet via le NAT Gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-rt-private"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────
# Recréée à chaque session car la key pair peut être perdue

resource "aws_key_pair" "deploy" {
  key_name   = var.key_pair_name
  public_key = var.public_key_content

  lifecycle {
    # Si elle existe déjà (session précédente), on la recrée proprement
    ignore_changes = []
  }
}

# ─── Security Group Bastion ───────────────────────────────────────────────────
# Seul point d'entrée SSH depuis internet

resource "aws_security_group" "bastion" {
  name        = "${var.app_name}-bastion-sg"
  description = "Security group for Bastion Host - SSH only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH depuis internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-bastion-sg"
  }
}

# ─── Security Group ALB ───────────────────────────────────────────────────────
# Accepte le trafic HTTP depuis internet

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Security group for ALB - HTTP from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

# ─── Security Group EC2 App ───────────────────────────────────────────────────
# Accepte le trafic uniquement depuis ALB et SSH depuis Bastion

resource "aws_security_group" "app" {
  name        = "${var.app_name}-app-sg"
  description = "Security group for App EC2 - traffic from ALB and Bastion only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH depuis Bastion uniquement"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Frontend depuis ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Gateway depuis ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-app-sg"
  }
}

# ─── Security Group RDS ───────────────────────────────────────────────────────
# Autorise uniquement l'EC2 à se connecter aux bases de données

resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Security group for RDS - PostgreSQL from App EC2 only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2 only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

# ─── Bastion Host ─────────────────────────────────────────────────────────────
# Petite instance publique servant uniquement de relai SSH vers l'EC2 privée

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deploy.key_name
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.app_name}-bastion"
  }
}

# ─── EC2 App ──────────────────────────────────────────────────────────────────
# Instance privée — accessible uniquement via Bastion et ALB

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deploy.key_name
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p ${var.deploy_path}
    chown ubuntu:ubuntu ${var.deploy_path}
  EOF

  tags = {
    Name = "${var.app_name}-app"
  }
}

# ─── RDS Subnet Group ─────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}

# ─── RDS Auth DB ──────────────────────────────────────────────────────────────

resource "aws_db_instance" "auth" {
  identifier        = "${var.app_name}-auth-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.auth_db_name
  username = var.auth_db_user
  password = var.auth_db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${var.app_name}-auth-db"
  }
}

# ─── RDS Product DB ───────────────────────────────────────────────────────────

resource "aws_db_instance" "product" {
  identifier        = "${var.app_name}-product-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.product_db_name
  username = var.product_db_user
  password = var.product_db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${var.app_name}-product-db"
  }
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# ─── ALB Target Groups ────────────────────────────────────────────────────────

resource "aws_lb_target_group" "front" {
  name     = "${var.app_name}-tg-front"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "${var.app_name}-tg-front"
  }
}

resource "aws_lb_target_group" "gateway" {
  name     = "${var.app_name}-tg-gateway"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "${var.app_name}-tg-gateway"
  }
}

# ─── ALB Target Group Attachments ─────────────────────────────────────────────

resource "aws_lb_target_group_attachment" "front" {
  target_group_arn = aws_lb_target_group.front.arn
  target_id        = aws_instance.app.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "gateway" {
  target_group_arn = aws_lb_target_group.gateway.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

# ─── ALB Listener HTTP ────────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Par défaut → frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
  }
}

# ─── ALB Listener Rules ───────────────────────────────────────────────────────

resource "aws_lb_listener_rule" "gateway" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }
}