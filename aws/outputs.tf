output "url_sistema_alb" { value = aws_lb.main_alb.dns_name }
output "ip_publico_monitoramento" { value = aws_instance.monitoramento.public_ip }
output "rds_endpoint" { value = aws_db_instance.estoque_db.endpoint }
output "s3_website_url" { value = aws_s3_bucket_website_configuration.frontend_web.website_endpoint }

output "chave_ssh_privada" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
