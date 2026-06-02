# ─── Bastion ──────────────────────────────────────────────────────────────────

output "bastion_public_ip" {
  description = "IP publique du Bastion Host"
  value       = aws_instance.bastion.public_ip
}

# ─── EC2 App ──────────────────────────────────────────────────────────────────

output "app_private_ip" {
  description = "IP privée de l'EC2 app (accessible uniquement via Bastion)"
  value       = aws_instance.app.private_ip
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

output "alb_dns" {
  description = "DNS du Load Balancer — point d'entrée de l'application"
  value       = aws_lb.main.dns_name
}

# ─── RDS ──────────────────────────────────────────────────────────────────────

output "auth_db_endpoint" {
  description = "Endpoint RDS de la base Auth"
  value       = aws_db_instance.auth.address
}

output "product_db_endpoint" {
  description = "Endpoint RDS de la base Product"
  value       = aws_db_instance.product.address
}