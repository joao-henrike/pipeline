output "resource_group_name" { value = azurerm_resource_group.main.name }
output "resource_group_id"   { value = azurerm_resource_group.main.id }
output "vnet_id"             { value = azurerm_virtual_network.main.id }
output "vnet_name"           { value = azurerm_virtual_network.main.name }
output "gateway_subnet_id"   { value = azurerm_subnet.gateway.id }
output "private_subnet_id"   { value = azurerm_subnet.private.id }
