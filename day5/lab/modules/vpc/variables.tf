# =============================================================================
# modules/vpc/variables.tf  —  This module's public "API" (inputs)
# =============================================================================

variable "name_prefix" {
  description = "Prefix applied to every resource name/tag this module creates."
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC's CIDR block — differs per environment so dev/qa never overlap."
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Common tags to apply to every resource (merged in, not overwritten)."
  type        = map(string)
  default     = {}
}
