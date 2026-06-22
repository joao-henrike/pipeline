variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "private_subnet_id" { type = string }
variable "aws_vpc_cidr" { type = string }
variable "admin_ip_cidrs" { type = list(string) }
variable "student_name" { type = string }
