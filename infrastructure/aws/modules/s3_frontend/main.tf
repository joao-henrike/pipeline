# =============================================================================
# MÓDULO S3 FRONTEND
# Hospeda o dashboard HTML/JS/CSS como site estático público no S3.
# O index.html recebe a URL do backend injetada via templatefile().
#
# Recursos:
#   aws_s3_bucket                  — bucket com nome único (account_id)
#   aws_s3_bucket_website_configuration — habilita static website hosting
#   aws_s3_bucket_public_access_block   — libera acesso público
#   aws_s3_bucket_policy           — policy GetObject para *
#   aws_s3_object (index.html)     — upload do dashboard com API_URL injetada
#   aws_s3_object (favicon)        — ícone opcional
# =============================================================================

data "aws_caller_identity" "current" {}

# ── Bucket com nome globalmente único
resource "aws_s3_bucket" "frontend" {
  bucket        = "multicloud-frontend-${var.student_name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "s3-frontend-${var.student_name}"
    Purpose = "Static Frontend Hosting"
  }
}

# ── Habilita website estático
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# ── Libera acesso público ao bucket
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ── ACL pública (necessário para website hosting)
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "frontend" {
  depends_on = [
    aws_s3_bucket_public_access_block.frontend,
    aws_s3_bucket_ownership_controls.frontend,
  ]
  bucket = aws_s3_bucket.frontend.id
  acl    = "public-read"
}

# ── Bucket Policy: permite leitura pública de todos os objetos
resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

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

# ── Upload do index.html com API_URL injetada via templatefile()
# O frontend JS usa this URL para chamar o backend FastAPI via VPN/Internet.
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.frontend.id
  key    = "index.html"

  # templatefile injeta a URL do backend no HTML antes do upload
  content      = templatefile("${path.module}/../../../../backend/templates/index.html.tpl", {
    api_url      = var.backend_api_url
    student_name = var.student_name
  })
  content_type = "text/html; charset=utf-8"

  depends_on = [aws_s3_bucket_policy.frontend]

  tags = { Name = "index.html" }
}

# ── Upload de arquivos estáticos adicionais (se existirem)
resource "aws_s3_object" "robots_txt" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "robots.txt"
  content      = "User-agent: *\nDisallow: /"
  content_type = "text/plain"
}
