# =============================================================================
# AWS MAIN.TF — Root Module (versão final completa)
#
# Módulos em ordem de dependência:
#   1. vpc            → VPC, subnets, IGW, NAT, route tables
#   2. key_pair       → Key Pair RSA (compartilhado por todas as EC2s)
#   3. security_groups → SGs: frontend, backend, monitoring
#   4. ec2_backend    → EC2 privada: Docker + Python + FastAPI + Node Exporter
#   5. ec2_frontend   → EC2 pública: Node.js 20 + Nginx (clona GitHub)
#   6. ec2_monitoring → EC2 pública: Prometheus + Grafana via Docker
#   7. vpn            → VGW + CGW + VPN Connection IKEv2
#   8. s3_frontend    → S3 static hosting (alternativa ao EC2 frontend)
# =============================================================================

# ── 1. VPC e Rede
module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.aws_vpc_cidr
  public_subnet_cidr  = var.aws_public_subnet_cidr
  private_subnet_cidr = var.aws_private_subnet_cidr
  availability_zone   = var.availability_zone
  student_name        = var.student_name
}

# ── 2. Key Pair RSA (compartilhado por todas as EC2s)
module "key_pair" {
  source       = "./modules/key_pair"
  student_name = var.student_name
}

# ── 3. Security Groups
module "security_groups" {
  source          = "./modules/security_groups"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr
  azure_vnet_cidr = var.azure_vnet_cidr
  admin_ip_cidrs  = var.admin_ip_cidrs
  student_name    = var.student_name
}

# ── 4. EC2 Backend (subnet PRIVADA — Docker + Python + FastAPI)
module "ec2_backend" {
  source            = "./modules/ec2_backend"
  private_subnet_id = module.vpc.private_subnet_id
  sg_id             = module.security_groups.backend_sg_id
  key_name          = module.key_pair.key_pair_name
  github_repo_url   = var.github_repo_url
  aws_region        = var.aws_region
  azure_vm_ip       = var.azure_vm_private_ip
  monitoring_ip     = ""
  student_name      = var.student_name
  instance_type     = var.backend_instance_type
}

# ── 5. EC2 Frontend (subnet PÚBLICA — Node.js + Nginx)
module "ec2_frontend" {
  source             = "./modules/ec2_frontend"
  public_subnet_id   = module.vpc.public_subnet_id
  sg_id              = module.security_groups.frontend_sg_id
  key_name           = module.key_pair.key_pair_name
  github_repo_url    = var.github_repo_url
  backend_private_ip = module.ec2_backend.private_ip
  student_name       = var.student_name
  instance_type      = var.frontend_instance_type
}

# ── 6. EC2 Monitoring (subnet PÚBLICA — Prometheus + Grafana)
module "ec2_monitoring" {
  source              = "./modules/ec2_monitoring"
  public_subnet_id    = module.vpc.public_subnet_id
  sg_id               = module.security_groups.monitoring_sg_id
  key_name            = module.key_pair.key_pair_name
  github_repo_url     = var.github_repo_url
  backend_private_ip  = module.ec2_backend.private_ip
  frontend_private_ip = module.ec2_frontend.private_ip
  azure_vm_ip         = var.azure_vm_private_ip
  grafana_password    = var.grafana_password
  student_name        = var.student_name
  instance_type       = var.monitoring_instance_type
}

# ── 7. VPN Gateway (VGW + CGW + Connection IKEv2)
module "vpn" {
  source                 = "./modules/vpn"
  vpc_id                 = module.vpc.vpc_id
  private_route_table_id = module.vpc.private_route_table_id
  azure_vpn_gateway_ip   = var.azure_vpn_gateway_ip
  azure_vnet_cidr        = var.azure_vnet_cidr
  vpn_shared_key         = var.vpn_shared_key
  vpn_bgp_asn            = var.vpn_bgp_asn
  create_vpn_tunnel      = var.create_vpn_tunnel
  student_name           = var.student_name
}

# ── 8. S3 Frontend (hospedagem estática alternativa)
module "s3_frontend" {
  source          = "./modules/s3_frontend"
  student_name    = var.student_name
  aws_region      = var.aws_region
  backend_api_url = "http://${module.ec2_frontend.public_ip}"
  depends_on      = [module.ec2_frontend]
}
