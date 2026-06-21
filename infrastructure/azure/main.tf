# =============================================================================
# AZURE MAIN.TF — Root Module
# =============================================================================

module "vnet" {
  source                    = "./modules/vnet"
  location                  = var.location
  environment               = var.environment
  student_name              = var.student_name
  azure_vnet_cidr           = var.azure_vnet_cidr
  azure_gateway_subnet_cidr = var.azure_gateway_subnet_cidr
  azure_private_subnet_cidr = var.azure_private_subnet_cidr
}

module "nsg" {
  source              = "./modules/nsg"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  private_subnet_id   = module.vnet.private_subnet_id
  aws_vpc_cidr        = var.aws_vpc_cidr
  admin_ip_cidrs      = var.admin_ip_cidrs
  student_name        = var.student_name
}

module "vm" {
  source              = "./modules/vm"
  location            = var.location
  resource_group_name = module.vnet.resource_group_name
  private_subnet_id   = module.vnet.private_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  student_name        = var.student_name
  depends_on          = [module.nsg]
}

module "vpn" {
  source                = "./modules/vpn"
  location              = var.location
  resource_group_name   = module.vnet.resource_group_name
  gateway_subnet_id     = module.vnet.gateway_subnet_id
  aws_vpc_cidr          = var.aws_vpc_cidr
  aws_tunnel1_ip        = var.aws_tunnel1_ip
  aws_tunnel2_ip        = var.aws_tunnel2_ip
  vpn_shared_key        = var.vpn_shared_key
  create_vpn_connection = var.create_vpn_connection
  vpn_gateway_sku       = var.vpn_gateway_sku
  student_name          = var.student_name
}
