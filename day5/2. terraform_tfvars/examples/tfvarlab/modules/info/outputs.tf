# =============================================================================
# modules/info/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "region_input" {
  description = "The value the root config PASSED IN to this module."
  value       = var.region
}

output "region_actually_in_use" {
  description = "What the AWS provider is REALLY using — independent proof, from data.aws_region."
  value       = data.aws_region.current.name
}

output "vpc_cidr_in_use" {
  value = var.vpc_cidr
}

output "owner_tag_in_use" {
  value = var.owner_tag
}

output "cost_center_in_use" {
  value = var.cost_center
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
