# IPs das Instancias EC2
output "ip_publico_frontend" { value = aws_instance.frontend_ui.public_ip }
output "ip_publico_backend" { value = aws_instance.backend_api.public_ip }
output "ip_publico_monitoramento" { value = aws_instance.monitoramento.public_ip }

# Endpoints e URLs
output "rds_endpoint" { value = aws_db_instance.estoque_db.endpoint }
output "s3_website_url" { value = aws_s3_bucket_website_configuration.frontend_web.website_endpoint }

# ==========================================
# CHAVE SSH PARA ACESSO ROOT
# ==========================================
output "chave_ssh_privada" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
