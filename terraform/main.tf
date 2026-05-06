# ================================
# Provider Docker
# ================================
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# ================================
# Réseau isolé par client
# ================================
resource "docker_network" "client_network" {
  name = "${var.client_prefix}-network"
}

# ================================
# Auth DB
# ================================
resource "docker_container" "auth_db" {
  name  = "${var.client_prefix}-auth-db"
  image = "postgres:15"

  env = [
    "POSTGRES_USER=${var.auth_db_user}",
    "POSTGRES_PASSWORD=${var.auth_db_password}",
    "POSTGRES_DB=${var.auth_db_name}"
  ]

  ports {
    internal = 5432
    external = var.auth_db_port
  }

  networks_advanced {
    name = docker_network.client_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.auth_db_user}"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 5
    start_period = "30s"
  }

  volumes {
    volume_name    = docker_volume.auth_data.name
    container_path = "/var/lib/postgresql/data"
  }
}

# ================================
# Product DB
# ================================
resource "docker_container" "product_db" {
  name  = "${var.client_prefix}-product-db"
  image = "postgres:15"

  env = [
    "POSTGRES_USER=${var.product_db_user}",
    "POSTGRES_PASSWORD=${var.product_db_password}",
    "POSTGRES_DB=${var.product_db_name}"
  ]

  ports {
    internal = 5432
    external = var.product_db_port
  }

  networks_advanced {
    name = docker_network.client_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.product_db_user}"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 5
    start_period = "30s"
  }

  volumes {
    volume_name    = docker_volume.product_data.name
    container_path = "/var/lib/postgresql/data"
  }
}

# ================================
# Auth Service
# ================================
resource "docker_container" "auth_service" {
  name  = "${var.client_prefix}-auth-service"
  image = "${var.client_prefix}-auth:latest"
  restart = "on-failure"

  env = [
    "ConnectionStrings__DockerDb=Host=${var.client_prefix}-auth-db;Database=${var.auth_db_name};Username=${var.auth_db_user};Password=${var.auth_db_password}",
    "JwtSettings__SecretKey=${var.jwt_secret}",
    "JwtSettings__Issuer=${var.jwt_issuer}",
    "JwtSettings__Audience=${var.jwt_audience}",
    "JwtSettings__ExpiryInMinutes=${var.jwt_expiry_minutes}"
  ]

  networks_advanced {
    name = docker_network.client_network.name
  }

  depends_on = [docker_container.auth_db]
}

# ================================
# Product Service
# ================================
resource "docker_container" "product_service" {
  name  = "${var.client_prefix}-product-service"
  image = "${var.client_prefix}-product:latest"
  restart = "on-failure"

  env = [
    "ConnectionStrings__DockerDb=Host=${var.client_prefix}-product-db;Database=${var.product_db_name};Username=${var.product_db_user};Password=${var.product_db_password}"
  ]

  ports {
    internal = 8080
    external = var.product_port
  }

  networks_advanced {
    name = docker_network.client_network.name
  }

  depends_on = [docker_container.product_db]
}

# ================================
# Gateway Service
# ================================
resource "docker_container" "gateway_service" {
  name  = "${var.client_prefix}-gateway-service"
  image = "${var.client_prefix}-gateway:latest"

  ports {
    internal = 8080
    external = var.gateway_port
  }

  networks_advanced {
    name = docker_network.client_network.name
  }

  depends_on = [
    docker_container.auth_service,
    docker_container.product_service
  ]
}

# ================================
# Front Service
# ================================
resource "docker_container" "front_service" {
  name  = "${var.client_prefix}-front-service"
  image = "${var.client_prefix}-front:latest"

  ports {
    internal = 80
    external = var.front_port
  }

  networks_advanced {
    name = docker_network.client_network.name
  }

  depends_on = [docker_container.gateway_service]
}

# ================================
# Volumes
# ================================
resource "docker_volume" "auth_data" {
  name = "${var.client_prefix}-auth-data"
}

resource "docker_volume" "product_data" {
  name = "${var.client_prefix}-product-data"
}