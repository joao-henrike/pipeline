provider "aws" { 
  region = "us-east-1" 
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "techstock-tfstate-joao-7733"
  tags   = { Name = "bucket-estado-terraform" }
}
