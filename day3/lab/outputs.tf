# =============================================================================
# outputs.tf
# =============================================================================

output "bucket_name" {
  description = "The generated name of the S3 bucket."
  value       = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  description = "The bucket's ARN."
  value       = aws_s3_bucket.example.arn
}

output "object_key" {
  description = "The key (path/name) of the uploaded object."
  value       = aws_s3_object.hello.key
}

output "account_id" {
  description = "The AWS account ID Terraform is authenticated against (from the data source)."
  value       = data.aws_caller_identity.current.account_id
}
