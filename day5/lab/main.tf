# =============================================================================
# main.tf  —  One VPC module, called once, deployed to whichever environment
# you pass via -var-file (Topic 2). The module itself never changes between
# environments — only the inputs (like vpc_cidr) do.
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  tags        = local.common_tags
}
