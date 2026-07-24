locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  # modules/eks derives its own cluster name the same way ("${name_prefix}-eks"
  # — see modules/eks/main.tf), so computing it once here and passing it to
  # modules/vpc for subnet tagging guarantees both always agree, without
  # modules/eks needing an explicit cluster_name input at all.
  cluster_name = "${local.name_prefix}-eks"

  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    Owner       = var.owner_tag
    Component   = "final-project"
    Course      = "Master Terraform"
    # Common real-world tag: tells anyone looking in the AWS Console this
    # resource is IaC-managed and shouldn't be hand-edited there.
    ManagedBy   = "terraform"
  }
}
