# =============================================================================
# locals.tf  —  Topic 1 (Locals) applied for real
# =============================================================================

locals {
  name_prefix = "${var.project_prefix}-${var.environment}"
  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    Owner       = var.owner_tag
    Day         = "03"
    Course      = "Master Terraform"
  }
}
