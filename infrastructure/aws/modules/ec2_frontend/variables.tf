variable "public_subnet_id"   { type = string }
variable "sg_id"              { type = string }
variable "key_name"           { type = string }
variable "backend_private_ip" {
  description = "IP privado da EC2 backend — usado no proxy Nginx e no .env Node.js"
  type        = string
}
variable "github_repo_url" {
  description = "URL HTTPS do repositório GitHub que contém frontend/, backend/, monitoring/"
  type        = string
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "student_name" { type = string }
