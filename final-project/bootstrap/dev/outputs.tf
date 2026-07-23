# =============================================================================
# outputs.tf  —  Confirm these match environments/dev/providers.tf's backend
# block exactly before ever running `terraform init` there.
# =============================================================================

output "state_bucket_name" {
  description = "Should equal environments/dev/providers.tf's backend bucket value."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  description = "Should equal environments/dev/providers.tf's backend dynamodb_table value."
  value       = aws_dynamodb_table.locks.name
}
