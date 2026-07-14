# =============================================================================
# main.tf  —  Topic 2 (IAM as Code) applied: a bucket + a role that can read it
# -----------------------------------------------------------------------------
# Read this file top to bottom — each STEP comment explains, in plain
# language, what that block actually does and WHY it's there.
# =============================================================================

# --- STEP 1: Look up which AWS account we're running in -----------------------
# Read-only lookup — creates NOTHING. We use this later to avoid hardcoding
# our 12-digit account number anywhere.
data "aws_caller_identity" "current" {}

# --- STEP 2: Generate a random suffix -----------------------------------------
# S3 bucket names must be globally unique across ALL of AWS. This produces a
# random hex string (e.g. "a1b2c3d4") so our bucket name never collides with
# anyone else's.
resource "random_id" "suffix" {
  byte_length = 4
}

# --- STEP 3: Create the S3 bucket ---------------------------------------------
# This is the actual thing the IAM role (built below) will be allowed to read.
resource "aws_s3_bucket" "app_data" {
  bucket = "${local.name_prefix}-${random_id.suffix.hex}"
  tags   = local.common_tags
}

# --- STEP 4: Define WHO is allowed to become this role (the TRUST policy) -----
# This says "the EC2 service — and only the EC2 service — may assume this
# role." Nothing here yet about what the role can actually DO once assumed.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# --- STEP 5: Create the IAM role itself ---------------------------------------
# This creates the role and attaches the trust policy from Step 4 to it via
# assume_role_policy. The role exists now, but it has ZERO permissions so far
# — creating a role grants no access by itself.
resource "aws_iam_role" "app_role" {
  name               = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

# --- STEP 6: Define WHAT the role can do (the PERMISSION policy) --------------
# Two statements, both scoped ONLY to the bucket from Step 3 — never "*":
#   - AllowListBucket: see what objects exist in the bucket
#   - AllowGetObjects:  read the contents of objects inside the bucket
data "aws_iam_policy_document" "s3_read_only" {
  statement {
    sid       = "AllowListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app_data.arn]
  }

  statement {
    sid       = "AllowGetObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app_data.arn}/*"]
  }
}

# --- STEP 7: Create the permission policy as a real AWS object ---------------
# The policy document from Step 6 is just JSON text until it's turned into an
# actual aws_iam_policy resource — this is that resource.
resource "aws_iam_policy" "s3_read_only" {
  name   = "${local.name_prefix}-s3-read-only"
  policy = data.aws_iam_policy_document.s3_read_only.json
}

# --- STEP 8: Attach the permission policy to the role -------------------------
# THIS is the step that actually grants the permission. Without it, the role
# from Step 5 and the policy from Step 7 would both exist but be completely
# disconnected — the role would still have NO permissions.
resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}
