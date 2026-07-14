# =============================================================================
# policy_document_vs_jsonencode.tf  —  Illustrative only, both produce IDENTICAL JSON
# -----------------------------------------------------------------------------
# `terraform validate` is enough to learn from this — see today's shared lab/
# for the real apply/destroy version.
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

# --- Option A: aws_iam_policy_document data source (recommended when authoring) --
data "aws_iam_policy_document" "ec2_assume_role_a" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "example_a" {
  name               = "example-role-a"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_a.json
}

# --- Option B: jsonencode() (useful when pasting JSON someone gave you) ----------
resource "aws_iam_role" "example_b" {
  name = "example-role-b"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

