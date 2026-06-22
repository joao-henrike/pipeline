# =============================================================================
# MÓDULO VNET AZURE
#
#  Resource Group
#  └── VNet 10.1.0.0/16
#      ├── GatewaySubnet 10.1.0.0/27  ← NOME OBRIGATÓRIO para VPN Gateway
#      └── Subnet Privada 10.1.1.0/24 ← VM principal
#
# ATENÇÃO: o subnet para VPN Gateway DEVE se chamar exatamente "GatewaySubnet"
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-multicloud-${var.student_name}"
  location = var.location
  tags = {
    Project     = "MultiCloud-VPN"
    Environment = var.environment
    Student     = var.student_name
    ManagedBy   = "Terraform"
    Cloud       = "Azure"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-multicloud-${var.student_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.azure_vnet_cidr]
  tags                = { Name = "vnet-multicloud-${var.student_name}" }
}

# Nome "GatewaySubnet" é OBRIGATÓRIO para VPN Gateway no Azure
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}

resource "azurerm_subnet" "private" {
  name                 = "subnet-private-${var.student_name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_private_subnet_cidr]
}
