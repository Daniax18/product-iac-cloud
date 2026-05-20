output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "IP publique de l'instance"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "DNS public de l'instance"
  value       = aws_instance.app.public_dns
}

# ─── RDS ──────────────────────────────────────────────────────────────────────

output "auth_db_endpoint" {
  description = "Endpoint RDS de la base Auth (sans le port)"
  value       = aws_db_instance.auth.address
}

output "product_db_endpoint" {
  description = "Endpoint RDS de la base Product (sans le port)"
  value       = aws_db_instance.product.address
}