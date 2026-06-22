# Criação do Bucket
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "techstock-frontend-joao-henrike"
  force_destroy = true

  tags = { Name = "techstock-frontend-s3" }
}

resource "aws_s3_bucket_ownership_controls" "frontend_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# CORREÇÃO: O S3 agora exige apenas "index.html" na raiz
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      },
    ]
  })
  depends_on = [
    aws_s3_bucket_public_access_block.frontend_public_access,
    aws_s3_bucket_ownership_controls.frontend_ownership
  ]
}

output "s3_website_endpoint" {
  description = "URL de acesso ao frontend hospedado no S3"
  value       = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
}
