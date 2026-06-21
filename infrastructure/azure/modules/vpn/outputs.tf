output "vpn_gateway_id"        { value = azurerm_virtual_network_gateway.vpn_gw.id }
output "vpn_gateway_public_ip" {
  description = "IP público do Azure VPN Gateway — copiar para aws_vpn_gateway_ip no AWS"
  value       = azurerm_public_ip.vpn_gw.ip_address
}
output "vpn_connection_status" {
  value = (var.create_vpn_connection && var.aws_tunnel1_ip != null
    ? "Connection criada para ${var.aws_tunnel1_ip}"
    : "PENDENTE — execute: make vpn-connect")
}
output "local_network_gateway_t1_id" {
  value = var.create_vpn_connection && var.aws_tunnel1_ip != null ? azurerm_local_network_gateway.aws_tunnel1[0].id : null
}
