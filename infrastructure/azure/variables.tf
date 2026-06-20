# =============================================================================
# AZURE VARIABLES.TF
# =============================================================================

variable "subscription_id" {
  description = "Azure Subscription ID (az account show --query id)"
  type        = string
}

variable "location" {
  description = "Região Azure (az account list-locations -o table)"
  type        = string
  default     = "eastus"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "student_name" {
  description = "Nome do aluno — sufixo de todos os recursos"
  type        = string
}

# ── Rede Azure
variable "azure_vnet_cidr" {
  description = "CIDR da VNet Azure. NÃO deve sobrepor o CIDR AWS."
  type        = string
  default     = "10.1.0.0/16"
}

variable "azure_gateway_subnet_cidr" {
  description = "CIDR do GatewaySubnet (OBRIGATÓRIO: /27 ou maior)"
  type        = string
  default     = "10.1.0.0/27"
}

variable "azure_private_subnet_cidr" {
  description = "CIDR da subnet privada (VM principal)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "admin_ip_cidrs" {
  description = "IPs autorizados a SSH na VM Azure"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_username" {
  description = "Username da VM Linux Azure"
  type        = string
  default     = "azureuser"
}

# ── Lado AWS (para configurar o Local Network Gateway Azure)
variable "aws_vpc_cidr" {
  description = "CIDR da VPC AWS — usado no Local Network Gateway Azure"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_tunnel1_ip" {
  description = "IP externo AWS Túnel 1 — obtido após terraform apply no AWS"
  type        = string
  default     = null
}

variable "aws_tunnel2_ip" {
  description = "IP externo AWS Túnel 2 (redundância)"
  type        = string
  default     = null
}

# ── VPN
variable "vpn_shared_key" {
  description = "Pre-Shared Key. MESMO VALOR que no AWS."
  type        = string
  sensitive   = true
  default     = "MultiCloudVPN@2024!"
}

variable "create_vpn_connection" {
  description = "true = cria LNG + Connection (requer aws_tunnel1_ip preenchido)"
  type        = bool
  default     = false
}

# ── VM
variable "vm_size" {
  description = "Tamanho da VM Azure"
  type        = string
  default     = "Standard_B1s"
}

variable "vpn_gateway_sku" {
  description = "SKU do VPN Gateway. VpnGw1 = compativel com AWS IKEv2."
  type        = string
  default     = "VpnGw1"
}
