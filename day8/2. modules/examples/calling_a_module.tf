# =============================================================================
# calling_a_module.tf  —  Illustrative only (matches modules.md §3-4)
# -----------------------------------------------------------------------------
# References ./modules/vpc and ./modules/compute — this file is meant to be
# READ alongside a real modules/ pair you build yourself following §2's
# anatomy, not run from this examples/ folder directly as-is.
# =============================================================================

# --- Calling a module once (matches §3) ----------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name_prefix    = "myapp-dev"
  vpc_cidr       = "10.0.0.0/16"
  public_subnets = { "us-east-1a" = "10.0.0.0/24" }
}

# --- Calling the SAME module twice, different inputs (matches §4) --------------
module "compute_web" {
  source         = "./modules/compute"
  name_prefix    = "myapp-dev-web"
  subnet_id      = module.vpc.public_subnet_ids["us-east-1a"]
  instance_count = 2
}

module "compute_worker" {
  source         = "./modules/compute"
  name_prefix    = "myapp-dev-worker"
  subnet_id      = module.vpc.public_subnet_ids["us-east-1a"]
  instance_count = 1
}

# Referencing a module's outputs works exactly like a resource's attributes:
output "vpc_id" {
  value = module.vpc.vpc_id
}
