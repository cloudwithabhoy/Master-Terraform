# =============================================================================
# depends_on_demo.tf  —  Illustrative only (matches depends_on.md §2-4)
# -----------------------------------------------------------------------------
# null_resource + the null provider let us demonstrate depends_on without
# needing a second real dependent AWS resource. Free to apply/destroy.
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

variable "bucket_purposes" {
  type = map(string)
  default = {
    logs    = "log-retention"
    backups = "disaster-recovery"
  }
}

resource "aws_s3_bucket" "example" {
  for_each = var.bucket_purposes
  bucket   = "depends-on-demo-${each.key}-${random_id.suffix.hex}"
  tags     = { Purpose = each.value }
}

# --- The depends_on pattern in practice ------------------------------------
# Nothing in this resource's arguments references the buckets — there's
# nothing here to build an implicit dependency FROM — so depends_on makes
# "wait until every bucket exists" explicit instead of accidental.
resource "null_resource" "buckets_ready" {
  depends_on = [aws_s3_bucket.example]

  triggers = {
    bucket_count = length(aws_s3_bucket.example)
  }
}

output "buckets_ready_id" {
  description = "Exists only after every bucket in aws_s3_bucket.example has been created."
  value       = null_resource.buckets_ready.id
}
