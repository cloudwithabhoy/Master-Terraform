# =============================================================================
# modules/vpc/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "subnet_id" {
  value = aws_subnet.this.id
}
