# =============================================================================
# main.tf  —  One module call. Same shape as day5/lab's modules/vpc pattern.
# =============================================================================

module "info" {
  source = "./modules/info"

  region      = var.region
  vpc_cidr    = var.vpc_cidr
  owner_tag   = var.owner_tag
  cost_center = var.cost_center
}
