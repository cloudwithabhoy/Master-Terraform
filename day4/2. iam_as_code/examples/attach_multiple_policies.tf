# =============================================================================
# attach_multiple_policies.tf  —  Illustrative only
# -----------------------------------------------------------------------------
# A role with TWO policies attached — its effective permissions are the union
# of both. `terraform validate` is enough to learn from this.
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

# =============================================================================
# TRUST POLICY EXAMPLE — answers "WHO can assume this role?"
# -----------------------------------------------------------------------------
# Use case: letting an EC2 instance (and ONLY the EC2 service) pick up this
# role automatically at launch — the trust policy is the guest list, it says
# nothing yet about what the role can actually DO.
# =============================================================================
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_role" {
  name               = "example-multi-policy-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json # <- the TRUST policy goes here
}

# =============================================================================
# PERMISSION POLICY EXAMPLE — answers "WHAT can this role do, once assumed?"
# -----------------------------------------------------------------------------
# Use case: scoping the role to read-only access on ONE specific bucket —
# e.g. an app server that needs to fetch config files but should never be
# able to write, delete, or touch any other bucket in the account.
# =============================================================================
data "aws_iam_policy_document" "s3_read_only" {
  statement {
    sid       = "AllowGetObjects"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::example-bucket/*"]
  }
}

resource "aws_iam_policy" "s3_read_only" {
  name   = "example-s3-read-only"
  policy = data.aws_iam_policy_document.s3_read_only.json # <- a PERMISSION policy, separate resource entirely
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

# --- Policy 2: write CloudWatch logs (a second, independent PERMISSION policy) --
# Use case: a second, unrelated grant on the SAME role — proves permission
# policies stack (the role's effective access is the union of all of them).
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid = "AllowLogging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name   = "example-cloudwatch-logs"
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logs" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# aws_role.app_role can now do BOTH: read example-bucket AND write logs —
# the union of every attached policy.
