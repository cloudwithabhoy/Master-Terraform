# =============================================================================
# variable_types.tf  —  Illustrative only (not wired to any resource)
# -----------------------------------------------------------------------------
# Run `terraform validate` in this folder to confirm these are all legal — no
# `terraform apply` needed, nothing here creates AWS resources.
# =============================================================================

# --- string --------------------------------------------------------------------
# Use case: a resource name/prefix, a region, an environment name — one scalar value.
variable "example_string" {
  type    = string
  default = "master-terraform"
}

# --- number ----------------------------------------------------------------------
# Use case: an instance count, a port number, a retention-in-days setting.
variable "example_number" {
  type    = number
  default = 2
}

# --- bool ------------------------------------------------------------------------
# Use case: a feature toggle, e.g. enable_versioning or enable_monitoring.
variable "example_bool" {
  type    = bool
  default = true
}

# --- list(string) ------------------------------------------------------------
# Use case: an ordered set of allowed environments, AZ names, or CIDR blocks.
variable "example_list" {
  type    = list(string)
  default = ["dev", "qa", "prod"]
}

# --- map(string) -------------------------------------------------------------
# Use case: a per-environment lookup, e.g. environment name -> its CIDR block.
variable "example_map" {
  type = map(string)
  default = {
    dev  = "10.0.0.0/24"
    qa   = "10.0.1.0/24"
    prod = "10.0.2.0/24"
  }
}

# --- object({...}) — a typed, structured value --------------------------------
# Use case: one structured settings bundle, e.g. a security group's config in one variable.
variable "example_object" {
  type = object({
    name        = string
    port        = number
    is_public   = bool
    cidr_blocks = list(string)
  })
  default = {
    name        = "web"
    port        = 443
    is_public   = true
    cidr_blocks = ["0.0.0.0/0"]
  }
}


