# =============================================================================
# version_operators.tf  —  Illustrative only (matches version_constraints.md §4)
# -----------------------------------------------------------------------------
# You can't actually declare required_providers twice for the same provider in
# one config, so these are shown as comments you can swap in one at a time.
# Run `terraform init` after changing the constraint to see it re-resolve.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # Pick ONE at a time and run `terraform init` to see what it resolves to:

      version = "~> 5.0" # allows 5.1, 5.9, 5.99... never 6.0 (THE common default)
      # version = "= 5.31.0"      # exactly this version, nothing else
      # version = ">= 5.0"        # 5.0 and anything newer, including 6.0+ (rarely what you want)
      # version = ">= 5.0, < 6.0" # explicit range — equivalent to ~> 5.0 but spelled out
      # version = "!= 5.20.0"     # anything except this one specific (known-bad) version
      # version = "~> 5.1.2"      # allows 5.1.3, 5.1.99... but not 5.2.0 (patch-only pin)
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# After `terraform init`, check what actually got resolved:
#   cat .terraform.lock.hcl
#   terraform providers
