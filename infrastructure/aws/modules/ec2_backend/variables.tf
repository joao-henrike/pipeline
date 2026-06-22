variable "private_subnet_id" { type = string }
variable "sg_id" { type = string }
variable "key_name" { type = string }
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "github_repo_url" {
  description = "URL do repositório GitHub"
  type        = string
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "azure_vm_ip" {
  description = "IP privado da VM Azure (para configurar OTHER_CLOUD_IP no .env)"
  type        = string
  default     = ""
}
variable "monitoring_ip" {
  description = "IP privado da EC2 de monitoramento"
  type        = string
  default     = ""
}
variable "student_name" { type = string }
