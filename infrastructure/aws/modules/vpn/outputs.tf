output "vpn_gateway_id" { value = aws_vpn_gateway.vgw.id }
output "vpn_connection_id" {
  value = var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null ? aws_vpn_connection.azure[0].id : null
}
output "vpn_tunnel1_outside_ip" {
  value = (var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null
    ? aws_vpn_connection.azure[0].tunnel1_address
  : "PENDENTE — execute: make vpn-connect")
}
output "vpn_tunnel2_outside_ip" {
  value = (var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null
    ? aws_vpn_connection.azure[0].tunnel2_address
  : "PENDENTE — execute: make vpn-connect")
}
output "vpn_tunnel1_preshared_key" {
  sensitive = true
  value = (var.create_vpn_tunnel && var.azure_vpn_gateway_ip != null
  ? aws_vpn_connection.azure[0].tunnel1_preshared_key : null)
}
