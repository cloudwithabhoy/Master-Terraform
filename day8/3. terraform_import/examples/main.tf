# =============================================================================
# main.tf  —  Your team's EXISTING, already-managed infrastructure.
# -----------------------------------------------------------------------------
# Apply this first (how_to_run.md Step 1) — it represents the real codebase
# you're adding an import INTO, not an empty folder. The EC2 instance you'll
# import later goes into import.tf, right alongside this.
# =============================================================================

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "import-demo-app-logs-${random_id.suffix.hex}"
  tags   = { ManagedBy = "terraform" }
}
