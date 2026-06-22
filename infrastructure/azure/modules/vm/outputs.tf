output "vm_id" { value = azurerm_linux_virtual_machine.vm.id }
output "vm_name" { value = azurerm_linux_virtual_machine.vm.name }
output "vm_private_ip" { value = azurerm_network_interface.vm.private_ip_address }
output "vm_public_ip" { value = azurerm_public_ip.vm.ip_address }
output "nic_id" { value = azurerm_network_interface.vm.id }
output "public_key_openssh" { value = tls_private_key.vm_key.public_key_openssh }
