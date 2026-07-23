# =============================================================================
# variables.tf  —  This config's inputs. The two names below MUST match
# environments/dev/providers.tf's backend "s3" block exactly, or that config
# will point at a bucket/table that doesn't exist.
# =============================================================================

variable "aws_region" {
  description = "AWS region — matches environments/dev/providers.tf's backend block region exactly."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Must match environments/dev/providers.tf's backend \"s3\" bucket value exactly."
  type        = string
  default     = "master-terraform-final-project-dev-tfstate"
}

variable "lock_table_name" {
  description = "Must match environments/dev/providers.tf's backend \"s3\" dynamodb_table value exactly."
  type        = string
  default     = "master-terraform-final-project-dev-locks"
}

variable "tags" {
  description = "Common tags to apply to every resource."
  type        = map(string)
  default = {
    Project     = "mtf"
    Environment = "dev"
    Component   = "final-project-bootstrap"
    Course      = "Master Terraform"
  }
}
