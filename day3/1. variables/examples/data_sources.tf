# =============================================================================
# data_sources.tf  —  Illustrative only
# -----------------------------------------------------------------------------
# Unlike the other two example files, THIS one needs real AWS credentials to
# `plan` (a data source still has to make an API call to look something up) —
# but it still creates nothing, so it's free and safe to run.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# A read-only lookup — appears in `terraform plan` marked `<=`, never `+` or `-`.
# Use case: building an account-scoped ARN/bucket name without hardcoding the account ID.
data "aws_caller_identity" "current" {}

# Use case: confirming (or logging) exactly which AWS account a plan/apply ran against.
output "account_id" {
  description = "The AWS account ID Terraform is currently authenticated against."
  value       = data.aws_caller_identity.current.account_id
}

# Use case: auditing/debugging — proving which IAM identity Terraform is using right now.
output "caller_arn" {
  description = "The ARN of the IAM user/role Terraform is running as."
  value       = data.aws_caller_identity.current.arn
}

# Try building an account-scoped ARN without ever hardcoding the account ID:
#   "arn:aws:s3:::my-bucket-${data.aws_caller_identity.current.account_id}"
