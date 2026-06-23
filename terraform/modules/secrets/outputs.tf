# PETPLAT-33: Secrets module outputs — ARNs only

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "git_username_secret_arn" {
  description = "ARN of the Git username secret (null if not created)"
  value       = var.git_username != null ? aws_secretsmanager_secret.git_username[0].arn : null
}

output "git_password_secret_arn" {
  description = "ARN of the Git password secret (null if not created)"
  value       = var.git_password != null ? aws_secretsmanager_secret.git_password[0].arn : null
}
