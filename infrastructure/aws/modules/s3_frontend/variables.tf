variable "student_name" {
  description = "Nome do aluno — sufixo e parte do nome do bucket"
  type        = string
}

variable "backend_api_url" {
  description = <<-EOT
    URL pública do backend FastAPI (ex: http://BASTION_IP:8000).
    Injetada no HTML do frontend antes do upload para o S3.
    O frontend JavaScript usa essa URL para chamar a API.
  EOT
  type    = string
  default = ""
}

variable "aws_region" {
  description = "Região AWS — usada para montar a URL do website S3"
  type        = string
  default     = "us-east-1"
}
