# =============================================================================
# AWS PROVIDERS.TF
# Projeto: Multi-Cloud VPN — AWS + Azure
# Declara os providers Terraform necessários para o lado AWS.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Opcional: descomente para usar backend remoto (S3)
  # backend "s3" {
  #   bucket = "seu-bucket-tfstate"
  #   key    = "multicloud/aws/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MultiCloud-VPN"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Student     = var.student_name
      Cloud       = "AWS"
    }
  }
}
