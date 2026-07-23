# =============================================================================
# main.tf  —  Calls the 6 active modules together for the dev environment
# (vpc, ecr, secrets, iam, eks, rds). See final-project/PROJECT.md and
# final-project/architecture.drawio for the full picture this assembles.
#
# The app's own Kubernetes resources (Deployments/Services/Ingress) are
# deliberately NOT here — see final-project/PROJECT.md's "Architecture
# decisions" (the real-world Terraform/app split). Those live as plain YAML
# in final-project/k8s/, applied by k8s-deploy.yml, a separate CI/CD job.
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

/* =============================================================================
   TEMPORARILY DISABLED — deploying incrementally: vpc + ecr only for now,
   to build understanding one piece at a time before wiring in the rest.
   Uncomment secrets/iam/eks/rds (in that order — each depends on the ones
   before it) plus the aws_secretsmanager_secret_version resource once ready
   to continue. Nothing here has changed except being wrapped in this
   comment block.
   =============================================================================

module "secrets" {
  source = "../../modules/secrets"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name_prefix        = local.name_prefix
  tags               = local.common_tags
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_role_arn             = module.iam.cluster_role_arn
  node_role_arn                = module.iam.node_role_arn
  node_role_policy_attachments = module.iam.node_role_policy_attachments

  db_secret_arn = module.secrets.secret_arn
  # backend_namespace / backend_service_account_name / node sizing /
  # kubernetes_version / alb_controller_chart_version all use modules/eks's
  # own defaults (see modules/eks/variables.tf) — nothing environment-
  # specific to override for dev.
}

module "rds" {
  source = "../../modules/rds"

  name_prefix               = local.name_prefix
  tags                      = local.common_tags
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  # No more per-tier "backend security group" now that the backend runs as a
  # pod, not its own EC2 instance — every pod on the node group carries
  # EKS's own cluster security group instead (see modules/eks/outputs.tf).
  backend_security_group_id = module.eks.cluster_security_group_id
  instance_class            = var.rds_instance_class
  master_username           = module.secrets.db_username
  master_password           = module.secrets.db_password
  multi_az                  = var.rds_multi_az
}

# --- Final secret value ------------------------------------------------------
# modules/secrets only creates the credential + secret container (see that
# module's header comment on why). Now that modules/rds exists, this is the
# ONE place the full connection info gets assembled — matches
# app/backend/app.py's expected secret shape exactly. The backend pod reads
# this via IRSA (module.eks.backend_irsa_role_arn, annotated on its
# ServiceAccount in final-project/k8s/backend-deployment.yaml) instead of an
# EC2 instance profile.
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = module.secrets.secret_id

  secret_string = jsonencode({
    username = module.secrets.db_username
    password = module.secrets.db_password
    host     = module.rds.address
    port     = module.rds.port
    dbname   = module.rds.db_name
  })
}

============================================================================= */
