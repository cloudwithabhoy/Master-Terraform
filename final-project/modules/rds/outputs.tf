# =============================================================================
# modules/rds/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "endpoint" {
  description = "host:port — the raw endpoint string RDS returns."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "Hostname only, no port — used by environments/dev/main.tf when assembling the final Secrets Manager value."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port RDS is listening on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "The initial database name."
  value       = aws_db_instance.this.db_name
}
