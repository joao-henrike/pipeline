resource "aws_s3_bucket" "frontend" {
  bucket = "techstock-frontend-ui-joao" # Altere se a AWS disser que o nome ja existe
  tags   = { Name = "bucket-frontend" }
}

resource "aws_s3_bucket_website_configuration" "frontend_web" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

# ==========================================
# DESBLOQUEIO DE ACESSO PÚBLICO
# ==========================================
resource "aws_s3_bucket_public_access_block" "frontend_access" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend_access]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}
