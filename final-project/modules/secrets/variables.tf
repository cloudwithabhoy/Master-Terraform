# =============================================================================
# modules/secrets/variables.tf  —  This module's public "API" (inputs)
# =============================================================================

variable "name_prefix" {
  description = "Prefix applied to every resource name/tag this module creates."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to every resource (merged in, not overwritten)."
  type        = map(string)
  default     = {}
}

variable "db_username" {
  description = "Master username for the RDS instance — stored in the secret alongside the generated password."
  type        = string
  default     = "appadmin"
}
