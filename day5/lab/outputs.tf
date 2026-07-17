output "vpc_id" {
  description = "This environment's VPC ID, from the vpc module."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_used" {
  description = "Confirms which CIDR this environment's .tfvars supplied."
  value       = module.vpc.vpc_cidr_block
}

output "subnet_id" {
  description = "This environment's subnet ID, from the vpc module."
  value       = module.vpc.subnet_id
}

output "environment" {
  description = "Which environment this run targeted — confirms the right .tfvars was loaded."
  value       = var.environment
}
