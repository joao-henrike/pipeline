variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "private_subnet_id" { type = string }
variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}
variable "admin_username" {
  type    = string
  default = "azureuser"
}
variable "student_name" { type = string }
