# =============================================================================
# variables.tf  —  Topic 1 (Variables) applied for real
# -----------------------------------------------------------------------------
# Every variable below has a `default`, so the lab runs out of the box with no
# flags needed. Try overriding one with -var to see precedence in action, e.g.:
#   terraform plan -var="environment=stage"
# =============================================================================

variable "project_prefix" {
  description = "Short name prefixed onto every resource this lab creates."
  type        = string
  default     = "master-terraform-day03"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_prefix))
    error_message = "project_prefix must be lowercase letters, numbers, and hyphens only."
  }
}

variable "environment" {
  description = "Which environment this is. Drives naming and tags, not real isolation today."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "owner_tag" {
  description = "Your name — recorded in the Owner tag so infra is traceable to a person."
  type        = string
  default     = "change-me"
}
