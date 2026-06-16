terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================
# 1. BUCKET S3 (REMOTE STATE)
# ==========================================
resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.bucket_name
  force_destroy = true 
  tags = { Name = "terraform-state-joao" }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

# ==========================================
# 2. OIDC & IAM ROLE PARA O GITHUB ACTIONS
# ==========================================
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612", "6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsTerraformRole-joao"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "StringEquals" = { "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com" }
          "StringLike"   = { "token.actions.githubusercontent.com:sub" : "repo:${var.github_repo}:*" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}