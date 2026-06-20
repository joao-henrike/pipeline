variable "private_subnet_id"     { type = string }
variable "public_subnet_id"      { type = string }
variable "ec2_sg_id"             { type = string }
variable "bastion_sg_id"         { type = string }
variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "bastion_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "create_bastion" {
  type    = bool
  default = true
}
variable "student_name" { type = string }
