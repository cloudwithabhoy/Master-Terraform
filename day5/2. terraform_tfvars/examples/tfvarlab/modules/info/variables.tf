# =============================================================================
# modules/info/variables.tf  —  This module's public "API" (inputs)
# =============================================================================

variable "region" {
  description = "Passed in from the root — the WINNER of the whole precedence chain."
  type        = string
}

variable "vpc_cidr" {
  description = "Passed in from the root — resolved from network.auto.tfvars, if present."
  type        = string
}

variable "owner_tag" {
  description = "Passed in from the root — resolved from a SEPARATE tags.auto.tfvars file."
  type        = string
}

variable "cost_center" {
  description = "Passed in from the root — set in BOTH auto.tfvars files, a same-stage tie."
  type        = string
}
