variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI (us-east-1)"
  type        = string
  default     = "ami-0e001c9271cf7f3b9"
}

variable "key_pair_name" {
  description = "Nom de la key pair EC2 à créer"
  type        = string
  default     = "iac-deploy-key"
}

variable "public_key_content" {
  description = "Contenu de la clé publique SSH (généré dans le CD)"
  type        = string
}

variable "app_name" {
  description = "Nom de l'application"
  type        = string
  default     = "iac-app"
}

variable "deploy_path" {
  description = "Chemin de déploiement sur EC2"
  type        = string
  default     = "/opt/iac-app"
}

# ─── RDS Auth DB ──────────────────────────────────────────────────────────────

variable "auth_db_name" {
  description = "Nom de la base de données Auth"
  type        = string
  default     = "authentication_db"
}

variable "auth_db_user" {
  description = "Utilisateur de la base de données Auth"
  type        = string
  default     = "postgres"
}

variable "auth_db_password" {
  description = "Mot de passe de la base de données Auth"
  type        = string
  sensitive   = true
}

# ─── RDS Product DB ───────────────────────────────────────────────────────────

variable "product_db_name" {
  description = "Nom de la base de données Product"
  type        = string
  default     = "product_db"
}

variable "product_db_user" {
  description = "Utilisateur de la base de données Product"
  type        = string
  default     = "postgres"
}

variable "product_db_password" {
  description = "Mot de passe de la base de données Product"
  type        = string
  sensitive   = true
}