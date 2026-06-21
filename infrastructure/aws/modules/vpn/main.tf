# =============================================================================
# MÓDULO VPN AWS
#
# Recursos AWS para o túnel Site-to-Site:
#
# [SEMPRE]  Virtual Private Gateway (VGW) — endpoint AWS, anexado à VPC
# [SEMPRE]  Route Propagation          — VGW propaga rotas na RT privada
# [FASE 2]  Customer Gateway (CGW)     — representa o Azure VPN Gateway
# [FASE 2]  VPN Connection             — túnel IPsec (2 túneis redundantes)
# [FASE 2]  VPN Static Route           — rota 10.1.0.0/16 via VPN
#
# Política IKEv2 compatível com Azure:
#   Phase 1 (IKE): AES256 + SHA256 + DH Group 2
#   Phase 2 (IPsec): AES256 + SHA256 + PFS Group 2
# =============================================================================

resource "aws_vpn_gateway" "vgw" {
  vpc_id = var.vpc_id
  tags   = { Name = "vgw-multicloud-${var.student_name}" }
}

# Propaga as rotas VPN aprendidas para a route table privada automaticamente
resource "aws_vpn_gateway_route_propagation" "private_rt" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = var.private_route_table_id
  depends_on     = [aws_vpn_gateway.vgw]
}

# ── FASE 2: Customer Gateway = Azure VPN Gateway
resource "aws_customer_gateway" "azure" {
  count      = var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null ? 1 : 0
  bgp_asn    = var.vpn_bgp_asn
  ip_address = var.azure_vpn_gateway_ip
  type       = "ipsec.1"
  tags       = { Name = "cgw-azure-${var.student_name}" }
}

# ── FASE 2: VPN Connection com política IKEv2 compatível com Azure
resource "aws_vpn_connection" "azure" {
  count               = var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.azure[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  # ── Tunnel 1 — principal
  tunnel1_preshared_key = var.vpn_shared_key
  tunnel1_inside_cidr   = "169.254.21.0/30"

  # IKEv2 Phase 1 (compatível com Azure)
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [2]
  tunnel1_phase1_lifetime_seconds      = 28800

  # IKEv2 Phase 2 (IPsec SA)
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["HMAC-SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [2]
  tunnel1_phase2_lifetime_seconds      = 3600

  # ── Tunnel 2 — redundância
  tunnel2_preshared_key = var.vpn_shared_key
  tunnel2_inside_cidr   = "169.254.22.0/30"

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [2]
  tunnel2_phase1_lifetime_seconds      = 28800

  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["HMAC-SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [2]
  tunnel2_phase2_lifetime_seconds      = 3600

  tags = { Name = "vpn-aws-azure-${var.student_name}" }
}

# ── FASE 2: Rota estática para o Azure VNet
resource "aws_vpn_connection_route" "azure_vnet" {
  count                  = var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null ? 1 : 0
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = var.azure_vnet_cidr
}
