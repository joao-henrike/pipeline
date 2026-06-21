variable "public_subnet_id"    { type = string }
variable "sg_id"               { type = string }
variable "key_name"            { type = string }
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "github_repo_url"     { type = string }
variable "backend_private_ip"  { type = string }
variable "frontend_private_ip" { type = string }
variable "azure_vm_ip" {
  type    = string
  default = ""
}
variable "grafana_password" {
  type      = string
  default   = "MultiCloudVPN@2024!"
  sensitive = true
}
variable "student_name" { type = string }
