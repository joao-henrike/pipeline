terraform {
  backend "s3" {
    bucket = "techstock-tfstate-joao-7733" # O bucket que já existe no seu AWS Academy
    key    = "aws/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

provider "aws" { region = "us-east-1" }
