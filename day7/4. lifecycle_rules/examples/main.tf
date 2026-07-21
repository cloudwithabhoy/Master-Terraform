resource "random_id" "suffix" {
  byte_length = 4
}

# --- prevent_destroy demo (matches §3) -----------------------------------------
resource "aws_s3_bucket" "critical" {
  bucket = "lifecycle-demo-critical-${random_id.suffix.hex}"
  #lifecycle {
  #  prevent_destroy = true
  #}
}

# --- ignore_changes demo (matches §4) ------------------------------------------
resource "aws_s3_bucket" "ignoring_tags" {
  bucket = "lifecycle-demo-ignore-tags-${random_id.suffix.hex}"
  tags   = { ManagedBy = "terraform" }

  lifecycle {
    ignore_changes = [tags] # a manual tag added later, e.g. via the console, won't show as drift
    #  ignore_changes = [tags] tells Terraform "don't compare this argument
    #  against reality at all" — trading away its ability to detect (or fix) any  drift on tags
  }
}

# --- create_before_destroy demo (matches §2) -----------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "web" {
  name   = "lifecycle-demo-rename-sg-${random_id.suffix.hex}"
  vpc_id = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }
}
