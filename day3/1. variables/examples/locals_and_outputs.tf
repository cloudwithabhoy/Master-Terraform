# =============================================================================
# locals_and_outputs.tf  —  Illustrative only (not wired to any resource)
# -----------------------------------------------------------------------------
# `terraform apply` here is safe — nothing creates AWS resources, it just
# computes locals and prints outputs.
# =============================================================================

# Use case: shared across every resource name in a config, so renaming a project is one edit.
variable "project_prefix" {
  type    = string
  default = "master-terraform"
}

# Use case: drives naming/tags AND (later) which .tfvars file gets loaded.
variable "environment" {
  type    = string
  default = "dev"
}

# Use case: traceability — who to ask when a resource shows up in a cost report.
variable "owner_tag" {
  type    = string
  default = "change-me"
}

# A pretend secret, purely to demonstrate `sensitive` below.
variable "alert_webhook_url" {
  type      = string
  default   = "https://example.com/replace-me"
  sensitive = true
}

# --- locals: computed once, referenced everywhere -----------------------------
# Use case: a naming/tagging convention shared by every resource in a config,
# so a naming rule change is a one-line edit instead of a find-and-replace.
locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    Owner       = var.owner_tag
  }
}

# --- outputs: what this config "returns" ---------------------------------------
# Use case: printing a computed value at the terminal, for a human to read.
output "name_prefix" {
  description = "Computed once in locals, printed here so you can see the result."
  value       = local.name_prefix
}

# Use case: exposing a value another script or CI step will consume programmatically.
output "common_tags" {
  description = "The tag map every real resource in this course applies."
  value       = local.common_tags
}

# Use case: returning a secret-like value without leaking it into logs/terminal output.
output "alert_webhook_url" {
  description = "Hidden by default because it's marked sensitive above."
  value       = var.alert_webhook_url
  sensitive   = true
}

# Try: terraform console
#   local.common_tags
#   local.name_prefix
# Try: terraform apply, then: terraform output alert_webhook_url
