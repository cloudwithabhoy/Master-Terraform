terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x, but not 6.0 (avoids surprise breaking changes)
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
