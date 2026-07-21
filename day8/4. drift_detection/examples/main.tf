# =============================================================================
# main.tf  —  Applyable (matches drift_detection.md's "Small illustrative
# snippet" section). One free S3 bucket — cheap/safe to apply and destroy.
# =============================================================================

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "demo" {
  bucket = "drift-demo-${random_id.suffix.hex}"
  tags   = { ManagedBy = "terraform" }
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
