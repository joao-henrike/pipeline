# =============================================================================
# MÓDULO NSG AZURE
# Network Security Group para a subnet privada da VM.
#
# Regras INBOUND:
#   - SSH   (22)   dos IPs admin
#   - ICMP  (ping) do AWS VPC via VPN
#   - SSH   (22)   do AWS VPC via VPN
#   - HTTP  (8000) do AWS VPC via VPN (backend)
#
# Regras OUTBOUND: tudo liberado
# =============================================================================

resource "azurerm_network_security_group" "vm_private" {
  name                = "nsg-vm-private-${var.student_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH admin externo
  security_rule {
    name                       = "AllowSSHAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_ip_cidrs
    destination_address_prefix = "*"
  }

  # ICMP do AWS via VPN (ping)
  security_rule {
    name                       = "AllowICMPFromAWS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  # SSH do AWS via VPN
  security_rule {
    name                       = "AllowSSHFromAWS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  # Backend HTTP do AWS via VPN
  security_rule {
    name                       = "AllowBackendFromAWS"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  # Saída total liberada
  security_rule {
    name                       = "AllowOutboundAll"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = { Name = "nsg-vm-private-${var.student_name}" }
}

# Associa o NSG à subnet privada
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = var.private_subnet_id
  network_security_group_id = azurerm_network_security_group.vm_private.id
}
