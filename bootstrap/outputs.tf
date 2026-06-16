output "github_actions_role_arn" {
  description = "Copie este ARN para usar na Pipeline"
  value       = aws_iam_role.github_actions_role.arn
}   