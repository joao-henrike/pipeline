resource "azurerm_resource_group" "rg_core" {
  name     = "rg-techstock-core"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-techstock"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_core.location
  resource_group_name = azurerm_resource_group.rg_core.name
}

resource "azurerm_subnet" "subnet_publica" {
  name                 = "snet-publica"
  resource_group_name  = azurerm_resource_group.rg_core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip_publico" {
  name                = "pip-techstock-base"
  location            = azurerm_resource_group.rg_core.location
  resource_group_name = azurerm_resource_group.rg_core.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg_base" {
  name                = "nsg-techstock-base"
  location            = azurerm_resource_group.rg_core.location
  resource_group_name = azurerm_resource_group.rg_core.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
