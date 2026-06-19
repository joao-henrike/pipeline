# ==========================================
# FRONTEND: HOSPEDAGEM ESTÁTICA EM S3
# ==========================================

resource "aws_s3_bucket" "frontend" {
  bucket        = "techstock-frontend-joao-7733" # Nome único global para o seu bucket
  force_destroy = true

  tags = {
    Name = "s3-frontend-techstock"
  }
}

# Configura o bucket para funcionar como Website
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  # O redirecionamento do erro para o index.html substitui o 'try_files' do Nginx
  error_document {
    key = "index.html"
  }
}

# Desbloqueia as regras de acesso público padrão da AWS para este bucket
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Aplica a política de leitura pública (Read-Only) para a internet
resource "aws_s3_bucket_policy" "public_read" {
  depends_on = [aws_s3_bucket_public_access_block.frontend]
  bucket     = aws_s3_bucket.frontend.id

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

# Output para cuspir a URL pública do seu sistema no final do deploy
output "frontend_s3_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
