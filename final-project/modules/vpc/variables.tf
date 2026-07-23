# =============================================================================
# modules/vpc/variables.tf  —  This module's public "API" (inputs)
# =============================================================================

variable "name_prefix" {
  description = "Prefix applied to every resource name/tag this module creates."
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC's CIDR block — differs per environment so dev/qa/prod never overlap."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly 2 AZs to spread subnets across — the ALB needs 2, and prod's RDS Multi-AZ standby needs the second private subnet (see final-project/PROJECT.md)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly 2 availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the 2 public subnets, one per AZ — the ALB (created by the AWS Load Balancer Controller) spans both; the single NAT Gateway lives in the first only."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnet CIDRs are required (one per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the 2 private subnets, one per AZ — the EKS node group + RDS primary in the first, RDS standby (prod Multi-AZ only) in the second."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly 2 private subnet CIDRs are required (one per AZ)."
  }
}

variable "cluster_name" {
  description = "EKS cluster name these subnets belong to — used to build the kubernetes.io/cluster/<name> and kubernetes.io/role/* tags EKS and the AWS Load Balancer Controller need for subnet auto-discovery."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to every resource (merged in, not overwritten)."
  type        = map(string)
  default     = {}
}
