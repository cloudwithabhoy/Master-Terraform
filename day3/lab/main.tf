

# --- Who am I? (a data source — this creates nothing) -------------------------
data "aws_caller_identity" "current" {}

# --- A random suffix — S3 bucket names are globally unique ---------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# --- The bucket ------------------------------------------------------------------
resource "aws_s3_bucket" "example" {
  bucket = "${local.name_prefix}-${random_id.suffix.hex}"
  tags   = local.common_tags
}

# --- An object INSIDE the bucket --------------------------------------------------
# Referencing the bucket here creates an IMPLICIT dependency: Terraform creates
# the bucket first, then the object; reverse order on destroy.
resource "aws_s3_object" "hello" {
  bucket       = aws_s3_bucket.example.id
  key          = "hello.txt"
  content      = "Hello from Terraform! You built this from code.\n"
  content_type = "text/plain"
}
