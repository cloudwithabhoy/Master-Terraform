# =============================================================================
# variables.tf  —  dev's root-level inputs. Real values come from dev.tfvars
# (gitignored — copy dev.tfvars.example and fill in your own; see that file).
#
# The EKS pivot removed several EC2/bastion-specific variables that used to
# live here (frontend/backend/bastion_instance_type, container_port, key_name,
# allowed_ssh_cidr) — nothing in this config consumes them anymore now that
# the app runs as Kubernetes pods instead of raw EC2 instances. See
# final-project/PROJECT.md's "Architecture decisions" for why the bastion
# itself was removed.
# =============================================================================

variable "project_prefix" {
  description = "Short prefix applied to every resource name/tag in this environment."
  type        = string
  default     = "mtf"
}

variable "environment" {
  description = "Environment name — used in tags/naming. Always \"dev\" for this root config."
  type        = string
  default     = "dev"
}

variable "owner_tag" {
  description = "Who owns/is responsible for this environment's resources (Day 5 Topic 1 tagging convention)."
  type        = string
}

variable "aws_region" {
  description = "AWS region — this course stays in one region throughout (Golden Rule #3)."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The VPC's CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly 2 AZs — see modules/vpc."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the 2 public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the 2 private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ — false in dev (final-project/PROJECT.md's architecture decisions: prod only)."
  type        = bool
  default     = false
}
