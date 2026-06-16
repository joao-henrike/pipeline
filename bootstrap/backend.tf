terraform {
  backend "s3" {
    bucket = "techstock-tfstate-joao"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}