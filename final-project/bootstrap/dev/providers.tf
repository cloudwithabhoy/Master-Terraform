# =============================================================================
# providers.tf  —  Local state, on purpose (Day 8 Topic 1 §4's bootstrap
# pattern). This config creates the S3 bucket + DynamoDB table that
# environments/dev's OWN backend depends on — it can't use that backend
# itself, since the bucket/table don't exist until THIS config applies.
# Run once, then left alone (see README.md).
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # No backend block — this is the one config in the whole project that
  # deliberately keeps local state (a terraform.tfstate file right here,
  # gitignored like every other local state file in this course).
}

provider "aws" {
  region = var.aws_region
}
