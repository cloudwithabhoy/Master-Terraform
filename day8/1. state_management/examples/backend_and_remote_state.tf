# =============================================================================
# backend_and_remote_state.tf  —  Illustrative only (matches state_management.md §2, §6)
# -----------------------------------------------------------------------------
# References a bucket/table that don't exist yet — this is reference material
# to read, not to `terraform init` as-is. Build the real bucket/table yourself
# first via the bootstrap pattern (§4 of state_management.md) before adapting
# this shape into a real consuming config.
# =============================================================================

# --- A config's own backend configuration (matches §2) -------------------------
terraform {
  backend "s3" {
    bucket         = "master-terraform-course-state"
    key            = "day08-networking/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "master-terraform-course-locks"
    encrypt        = true
  }
}

# --- Reading a DIFFERENT config's outputs (matches §6) -------------------------
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "master-terraform-course-state"
    key    = "day08-networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Example of consuming it elsewhere:
#   resource "aws_instance" "app" {
#     subnet_id = data.terraform_remote_state.networking.outputs.public_subnet_id
#   }
