# =============================================================================
# MÓDULO VPN AZURE
#
# Recursos para o túnel Site-to-Site Azure → AWS:
#
# [SEMPRE]  Public IP do VPN Gateway     — IP que a AWS usa como CGW
# [SEMPRE]  Virtual Network Gateway      — endpoint Azure do túnel VPN
#           SKU: VpnGw1 (requerido para IKEv2 com AWS)
#           Type: RouteBased             — compatível com AWS VGW
#
# [FASE 2]  Local Network Gateway        — representa o endpoint AWS (tunnel IPs)
# [FASE 2]  VPN Connection               — conexão IPsec com política IKEv2
#
# Política IPsec compatível com AWS IKEv2:
#   IKE Phase 1: AES256 + SHA256 + DH Group 2 + lifetime 28800s
#   IKE Phase 2: AES256 + SHA256 + PFS Group 2 + lifetime 3600s
# =============================================================================

# ── IP Público do VPN Gateway (SEMPRE criado — AWS precisa deste IP)
resource "azurerm_public_ip" "vpn_gw" {
  name                = "pip-vpngw-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { Name = "pip-vpngw-${var.student_name}" }
}

# ── Virtual Network Gateway (SEMPRE criado)
# Tempo de criação: ~30-45 minutos
resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = "vpngw-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  tags = { Name = "vpngw-${var.student_name}" }
}

# ── FASE 2: Local Network Gateway — Túnel 1 AWS
# Representa o endpoint AWS (tunnel1_outside_ip)
resource "azurerm_local_network_gateway" "aws_tunnel1" {
  count               = var.create_vpn_connection && var.aws_tunnel1_ip != null ? 1 : 0
  name                = "lng-aws-t1-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.aws_tunnel1_ip
  address_space       = [var.aws_vpc_cidr]
  tags                = { Name = "lng-aws-t1-${var.student_name}" }
}

# ── FASE 2: Local Network Gateway — Túnel 2 AWS (redundância)
resource "azurerm_local_network_gateway" "aws_tunnel2" {
  count               = var.create_vpn_connection && var.aws_tunnel2_ip != null ? 1 : 0
  name                = "lng-aws-t2-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.aws_tunnel2_ip
  address_space       = [var.aws_vpc_cidr]
  tags                = { Name = "lng-aws-t2-${var.student_name}" }
}

# ── FASE 2: VPN Connection — Túnel 1 (principal)
resource "azurerm_virtual_network_gateway_connection" "aws_tunnel1" {
  count                      = var.create_vpn_connection && var.aws_tunnel1_ip != null ? 1 : 0
  name                       = "conn-aws-t1-${var.student_name}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_tunnel1[0].id
  shared_key                 = var.vpn_shared_key

  # Política IPsec compatível com AWS IKEv2
  ipsec_policy {
    dh_group         = "DHGroup2"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2"
    sa_datasize      = 102400000
    sa_lifetime      = 3600
  }

  tags = { Name = "conn-aws-t1-${var.student_name}" }
}

# ── FASE 2: VPN Connection — Túnel 2 (redundância)
resource "azurerm_virtual_network_gateway_connection" "aws_tunnel2" {
  count                      = var.create_vpn_connection && var.aws_tunnel2_ip != null ? 1 : 0
  name                       = "conn-aws-t2-${var.student_name}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_tunnel2[0].id
  shared_key                 = var.vpn_shared_key

  ipsec_policy {
    dh_group         = "DHGroup2"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2"
    sa_datasize      = 102400000
    sa_lifetime      = 3600
  }

  tags = { Name = "conn-aws-t2-${var.student_name}" }
}
