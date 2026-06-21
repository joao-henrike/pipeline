# =============================================================================
# MÓDULO VM AZURE
# Cria: Key Pair SSH + IP Público + NIC + VM Linux Ubuntu 20.04
# O custom_data instala automaticamente as ferramentas de teste de rede
# e o backend FastAPI.
# =============================================================================

resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.vm_key.private_key_pem
  filename        = "${path.root}/keys/key-azure-${var.student_name}.pem"
  file_permission = "0400"
}

# IP público para acesso SSH admin
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { Name = "pip-vm-${var.student_name}" }
}

# Network Interface — conecta a VM à subnet privada
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.student_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig-vm-${var.student_name}"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = { Name = "nic-vm-${var.student_name}" }
}

# VM Linux Ubuntu 20.04 LTS
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-azure-${var.student_name}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vm_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # Script de inicialização: instala ferramentas + backend
  custom_data = base64encode(templatefile("${path.module}/cloud_init.sh", {
    student_name   = var.student_name
    admin_username = var.admin_username
  }))

  tags = {
    Name = "vm-azure-${var.student_name}"
    Role = "VPN-Target"
    OS   = "Ubuntu-20.04"
  }
}
