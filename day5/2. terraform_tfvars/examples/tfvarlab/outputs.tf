# =============================================================================
# outputs.tf  —  No resources created — safe to `terraform apply` immediately,
# nothing to destroy afterward either.
# =============================================================================

output "region_in_use" {
  description = "Should read ap-south-1 — network.auto.tfvars beats terraform.tfvars's us-east-1, which already beat the eu-central-1 default."
  value       = module.info.region_actually_in_use
}

output "vpc_cidr_in_use" {
  description = "Should read 172.16.0.0/16 — from network.auto.tfvars, not the 10.0.0.0/16 default."
  value       = module.info.vpc_cidr_in_use
}

output "owner_tag_in_use" {
  description = "Should read platform-team — from tags.auto.tfvars, a SEPARATE file, not the nobody default."
  value       = module.info.owner_tag_in_use
}

output "cost_center_in_use" {
  description = "Should read CC-TAGS (tags.auto.tfvars) — it loads AFTER network.auto.tfvars alphabetically ('n' < 't'), so it wins the tie."
  value       = module.info.cost_center_in_use
}

output "account_id" {
  value = module.info.account_id
}
