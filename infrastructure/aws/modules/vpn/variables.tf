variable "vpc_id" { type = string }
variable "private_route_table_id" { type = string }
variable "azure_vpn_gateway_ip" {
  type    = string
  default = null
}
variable "azure_vnet_cidr" { type = string }
variable "vpn_shared_key" {
  type      = string
  sensitive = true
}
variable "vpn_bgp_asn" {
  type    = number
  default = 65000
}
variable "create_vpn_tunnel" {
  type    = bool
  default = false
}
variable "student_name" { type = string }
