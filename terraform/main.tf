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
    bucket = "iac-terraform-state-bucket-midera-01"   # à adapter, voir étapes AWS Academy
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
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

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "app" {
  name        = "${var.app_name}-sg"
  description = "Security group for ${var.app_name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Gateway"
    from_port   = 8080
    to_port     = 8080
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
    Name = "${var.app_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deploy.key_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

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
    Name = var.app_name
  }
}