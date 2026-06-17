resource "aws_s3_bucket" "frontend" {
  bucket = "techstock-frontend-ui-joao" # Altere se der conflito de nome
  tags   = { Name = "bucket-frontend" }
}

resource "aws_s3_bucket_website_configuration" "frontend_web" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}
