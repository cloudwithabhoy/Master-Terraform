# =============================================================================
# modules/secrets/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "secret_id" {
  description = "Secret ID/name — environments/dev/main.tf uses this to create the final secret version once RDS exists."
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "secret_arn" {
  description = "Secret ARN — consumed by modules/iam to scope the backend role's read permission."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_username" {
  description = "Generated RDS master username — feeds into modules/rds."
  value       = var.db_username
}

output "db_password" {
  description = "Generated RDS master password — feeds into modules/rds. Sensitive: never printed in plan/apply output."
  value       = random_password.db.result
  sensitive   = true
}
