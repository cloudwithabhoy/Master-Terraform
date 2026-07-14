output "bucket_name" {
  description = "The generated name of the S3 bucket the role can read."
  value       = aws_s3_bucket.app_data.bucket
}

output "role_arn" {
  description = "ARN of the IAM role created for EC2 to assume (used again on Day 7)."
  value       = aws_iam_role.app_role.arn
}

output "policy_arn" {
  description = "ARN of the scoped S3-read-only policy attached to the role."
  value       = aws_iam_policy.s3_read_only.arn
}

output "account_id" {
  description = "The AWS account ID Terraform is authenticated against (from the data source)."
  value       = data.aws_caller_identity.current.account_id
}
