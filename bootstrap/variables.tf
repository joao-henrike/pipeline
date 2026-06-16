variable "aws_region" {
  description = "Regiao da AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nome globalmente unico para o S3 do Terraform State"
  type        = string
  default     = "techstock-tfstate-joao-7733" # Se a AWS avisar que o nome já existe, basta alterar estes números finais
}

variable "github_repo" {
  description = "Usuario/Repositorio no GitHub"
  type        = string
  default     = "joao-henrike/pipeline"
}