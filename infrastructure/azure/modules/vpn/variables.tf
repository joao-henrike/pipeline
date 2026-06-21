variable "location"             { type = string }
variable "resource_group_name"  { type = string }
variable "gateway_subnet_id"    { type = string }
variable "aws_vpc_cidr"         { type = string }
variable "aws_tunnel1_ip" {
  type    = string
  default = null
}
variable "aws_tunnel2_ip" {
  type    = string
  default = null
}
variable "vpn_shared_key" {
  type      = string
  sensitive = true
}
variable "create_vpn_connection" {
  type    = bool
  default = false
}
variable "vpn_gateway_sku" {
  type    = string
  default = "VpnGw1"
}
variable "student_name" { type = string }
