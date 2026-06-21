# =============================================================================
# AWS OUTPUTS.TF (versão final)
# =============================================================================

# ── Rede
output "vpc_id"      { value = module.vpc.vpc_id }
output "vpc_cidr"    { value = module.vpc.vpc_cidr }

# ── Chave SSH
output "key_pair_name" { value = module.key_pair.key_pair_name }
output "key_file"      { value = "infrastructure/aws/keys/key-multicloud-${var.student_name}.pem" }

# ── EC2 Frontend (Node.js + Nginx)
output "frontend_public_ip"  { value = module.ec2_frontend.public_ip }
output "frontend_url"        { value = "http://${module.ec2_frontend.public_ip}" }
output "frontend_node_url"   { value = "http://${module.ec2_frontend.public_ip}:3000" }

# ── EC2 Backend (FastAPI)
output "backend_private_ip"  { value = module.ec2_backend.private_ip }
output "backend_api_url"     { value = module.ec2_backend.backend_url }

# ── EC2 Monitoring (Prometheus + Grafana)
output "grafana_url"         { value = module.ec2_monitoring.grafana_url }
output "prometheus_url"      { value = module.ec2_monitoring.prometheus_url }
output "monitoring_public_ip"{ value = module.ec2_monitoring.public_ip }

# ── VPN
output "vpn_gateway_id"         { value = module.vpn.vpn_gateway_id }
output "vpn_tunnel1_outside_ip" { value = module.vpn.vpn_tunnel1_outside_ip }
output "vpn_tunnel2_outside_ip" { value = module.vpn.vpn_tunnel2_outside_ip }

# ── S3 Frontend
output "s3_frontend_url"     { value = module.s3_frontend.website_url }
output "s3_bucket_name"      { value = module.s3_frontend.bucket_name }

# ── SSH helpers
output "cmd_ssh_frontend" {
  value = "ssh -i infrastructure/aws/keys/key-multicloud-${var.student_name}.pem ec2-user@${module.ec2_frontend.public_ip}"
}
output "cmd_ssh_backend" {
  value = "ssh -i infrastructure/aws/keys/key-multicloud-${var.student_name}.pem -J ec2-user@${module.ec2_frontend.public_ip} ec2-user@${module.ec2_backend.private_ip}"
}
output "cmd_ssh_monitoring" {
  value = "ssh -i infrastructure/aws/keys/key-multicloud-${var.student_name}.pem ec2-user@${module.ec2_monitoring.public_ip}"
}

# ── Para o Azure (Fase 2)
output "azure_config_required" {
  value = {
    aws_tunnel1_ip        = module.vpn.vpn_tunnel1_outside_ip
    aws_tunnel2_ip        = module.vpn.vpn_tunnel2_outside_ip
    aws_vpc_cidr          = module.vpc.vpc_cidr
    create_vpn_connection = "true"
  }
}
