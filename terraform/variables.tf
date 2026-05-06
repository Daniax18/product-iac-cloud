# ================================
# Variables Terraform
# ================================

# Identité client
variable "client_name" {
  description = "Nom du client"
  type        = string
}

variable "client_siege" {
  type        = string
  description = "Siège social du client"
}


variable "client_prefix" {
  description = "Préfixe unique par client (ex: clienta)"
  type        = string
}

# Ports
variable "front_port" {
  description = "Port exposé du frontend Angular"
  type        = string
}

variable "gateway_port" {
  description = "Port exposé de la gateway Java"
  type        = string
}

variable "auth_db_port" {
  description = "Port exposé de la DB Auth"
  type        = string
}

variable "product_port" {
  description = "Port exposé du service Product"
  type        = string
}

variable "product_db_port" {
  description = "Port exposé de la DB Product"
  type        = string
}

# Base de données Auth
variable "auth_db_user" {
  description = "Utilisateur PostgreSQL Auth"
  type        = string
}

variable "auth_db_password" {
  description = "Mot de passe PostgreSQL Auth"
  type        = string
  sensitive   = true
}

variable "auth_db_name" {
  description = "Nom de la base Auth"
  type        = string
}

# Base de données Product
variable "product_db_user" {
  description = "Utilisateur PostgreSQL Product"
  type        = string
}

variable "product_db_password" {
  description = "Mot de passe PostgreSQL Product"
  type        = string
  sensitive   = true
}

variable "product_db_name" {
  description = "Nom de la base Product"
  type        = string
}

# JWT
variable "jwt_secret" {
  description = "Clé secrète JWT"
  type        = string
  sensitive   = true
}

variable "jwt_issuer" {
  description = "Issuer JWT"
  type        = string
}

variable "jwt_audience" {
  description = "Audience JWT"
  type        = string
}

variable "jwt_expiry_minutes" {
  description = "Durée de validité du token JWT en minutes"
  type        = string
}