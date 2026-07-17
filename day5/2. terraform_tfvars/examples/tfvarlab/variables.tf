# =============================================================================
# variables.tf  —  Every default here is DELIBERATELY the loser in this
# folder's precedence chain — see tfvarlab.md for the full walkthrough.
# =============================================================================

variable "region" {
  description = "Set in BOTH terraform.tfvars AND network.auto.tfvars — this proves which one wins."
  type        = string
  default     = "eu-central-1" # <- loses to everything else in this folder
}

variable "vpc_cidr" {
  description = "Set ONLY in network.auto.tfvars."
  type        = string
  default     = "10.0.0.0/16" # <- loses to network.auto.tfvars
}

variable "owner_tag" {
  description = "Set ONLY in tags.auto.tfvars — a SEPARATE file from network.auto.tfvars."
  type        = string
  default     = "nobody" # <- loses to tags.auto.tfvars
}

variable "cost_center" {
  description = "Set in BOTH network.auto.tfvars AND tags.auto.tfvars — a tie WITHIN Stage 2, broken alphabetically by filename."
  type        = string
  default     = "unassigned" # <- loses to both auto.tfvars files
}
