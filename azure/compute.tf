resource "azurerm_network_interface" "nic_base" {
  name                = "nic-techstock-base"
  location            = azurerm_resource_group.rg_core.location
  resource_group_name = azurerm_resource_group.rg_core.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_publica.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip_publico.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_link" {
  network_interface_id      = azurerm_network_interface.nic_base.id
  network_security_group_id = azurerm_network_security_group.nsg_base.id
}

resource "azurerm_linux_virtual_machine" "vm_base" {
  name                = "vm-techstock-base"
  resource_group_name = azurerm_resource_group.rg_core.name
  location            = azurerm_resource_group.rg_core.location
  size                = "Standard_B1s"
  admin_username      = "sysadmin"

  network_interface_ids = [
    azurerm_network_interface.nic_base.id,
  ]

  admin_ssh_key {
    username   = "sysadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

output "azure_vm_public_ip" {
  value = azurerm_public_ip.ip_publico.ip_address
}
