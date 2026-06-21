output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

output "website_endpoint" {
  description = "URL pública do frontend hospedado no S3"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "website_url" {
  description = "URL completa (http) do dashboard frontend"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "account_id" {
  description = "AWS Account ID (usado no nome do bucket)"
  value       = data.aws_caller_identity.current.account_id
}
