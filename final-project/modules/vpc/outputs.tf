# =============================================================================
# modules/vpc/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "vpc_id" {
  description = "The VPC's ID — every other module needs this."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The VPC's CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Both public subnet IDs (one per AZ) — the ALB needs both."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Both private subnet IDs (one per AZ)."
  value       = [for az in var.availability_zones : aws_subnet.private[az].id]
}

output "public_subnet_id_primary" {
  description = "The first AZ's public subnet — where the single NAT Gateway lives."
  value       = aws_subnet.public[var.availability_zones[0]].id
}

output "private_subnet_id_primary" {
  description = "The first AZ's private subnet — where the EKS node group and RDS primary live."
  value       = aws_subnet.private[var.availability_zones[0]].id
}

output "private_subnet_id_secondary" {
  description = "The second AZ's private subnet — used only for RDS's Multi-AZ standby in prod."
  value       = aws_subnet.private[var.availability_zones[1]].id
}

output "nat_gateway_id" {
  description = "The single NAT Gateway's ID."
  value       = aws_nat_gateway.this.id
}
