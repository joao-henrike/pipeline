output "resource_group_name"   { value = module.vnet.resource_group_name }
output "vnet_id"               { value = module.vnet.vnet_id }
output "vnet_cidr"             { value = var.azure_vnet_cidr }
output "private_subnet_id"     { value = module.vnet.private_subnet_id }

output "vm_private_ip" {
  description = "IP privado da VM Azure — alvo do ping/SSH do AWS via VPN"
  value       = module.vm.vm_private_ip
}
output "vm_public_ip" {
  description = "IP público da VM Azure (acesso SSH admin)"
  value       = module.vm.vm_public_ip
}
output "vm_admin_username" { value = var.admin_username }

output "vpn_gateway_public_ip" {
  description = "IP público do Azure VPN Gateway — informar ao AWS como azure_vpn_gateway_ip"
  value       = module.vpn.vpn_gateway_public_ip
}
output "vpn_connection_status" { value = module.vpn.vpn_connection_status }

output "ssh_vm_azure" {
  value = "ssh -i keys/key-azure-${var.student_name}.pem ${var.admin_username}@${module.vm.vm_public_ip}"
}
output "ping_aws_from_azure" {
  value = "ping <ec2_private_ip>   # executar NA VM Azure após VPN ativa"
}
