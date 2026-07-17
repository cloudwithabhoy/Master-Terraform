# =============================================================================
# variables.tf  —  Values come from environments/*.tfvars today (Topic 2),
# not -var flags. No default on `environment` on purpose — forces you to pass
# -var-file, exactly like a real multi-env setup would.
# =============================================================================

variable "project_prefix" {
  description = "Short name prefixed onto every resource this lab creates."
  type        = string
  default     = "master-terraform-day05"
}

variable "environment" {
  description = "Which environment this is — REQUIRED, supplied by an environments/*.tfvars file."
  type        = string


}

variable "owner_tag" {
  description = "Your name — recorded in the Owner tag so infra is traceable to a person."
  type        = string
  default     = "change-me"
}

# A value that legitimately differs per environment — dev and qa get
# non-overlapping CIDR ranges, driven entirely by environments/*.tfvars
# (no code change needed to change this per environment).
variable "vpc_cidr" {
  description = "This environment's VPC CIDR block."
  type        = string
  default     = "30.0.0.0/16"
}
