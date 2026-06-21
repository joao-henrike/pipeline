resource "aws_s3_bucket" "frontend" {
  # Adicionando seu nome para garantir unicidade global no S3
  bucket        = "techstock-frontend-s3-hibrido-joao"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "frontend_hosting" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}
