variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "student_name" {
  type = string
}
variable "aws_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "aws_public_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
variable "aws_private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}
variable "admin_ip_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "azure_vnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
variable "azure_vpn_gateway_ip" {
  type    = string
  default = null
}
variable "azure_vm_private_ip" {
  type    = string
  default = ""
}
variable "create_vpn_tunnel" {
  type    = bool
  default = false
}
variable "vpn_shared_key" {
  type      = string
  sensitive = true
  default   = "MultiCloudVPN@2024!"
}
variable "vpn_bgp_asn" {
  type    = number
  default = 65000
}
variable "github_repo_url" {
  description = "URL HTTPS do repositorio GitHub (clonado em todas as EC2s no boot)"
  type        = string
  default     = "https://github.com/SEU_USUARIO/multicloud-vpn-project.git"
}
variable "frontend_instance_type" {
  type    = string
  default = "t3.small"
}
variable "backend_instance_type" {
  type    = string
  default = "t3.small"
}
variable "monitoring_instance_type" {
  type    = string
  default = "t3.small"
}
variable "grafana_password" {
  description = "Senha admin do Grafana"
  type        = string
  sensitive   = true
  default     = "MultiCloudVPN@2024!"
}
variable "backend_api_url" {
  type    = string
  default = ""
}
