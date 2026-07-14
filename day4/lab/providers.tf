# =============================================================================
# providers.tf  —  Topic 1 (Version Constraints) applied for real
# -----------------------------------------------------------------------------
# required_version and each provider's version constraint are exactly what
# Topic 1 covered — this is not a toy example, it's the real constraint every
# lab in this course uses.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x, but not 6.0 — see version_constraints.md §4
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # Credentials come from `aws configure` (~/.aws/credentials).
  # NEVER hard-code access keys here.
}
