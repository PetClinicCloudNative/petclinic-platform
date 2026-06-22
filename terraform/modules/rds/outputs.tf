# PETPLAT-22: RDS module outputs

output "endpoint" {
  description = "RDS instance endpoint address"
  value       = aws_db_instance.main.endpoint
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

# PETPLAT-23: Secret ARN output
output "secret_arn" {
  description = "ARN of the RDS credentials secret in Secrets Manager"
  value       = aws_secretsmanager_secret.rds.arn
}
