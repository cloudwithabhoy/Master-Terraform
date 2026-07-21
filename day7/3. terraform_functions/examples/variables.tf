variable "environment" {
  description = "Which environment this is — drives size, name, and tags below."
  type        = string
  default     = "prod"

  # contains(): validate the value is one of an allowed set.
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "instance_types" {
  description = "Map of environment => instance type. lookup() reads this by var.environment."
  type        = map(string)
  default = {
    dev  = "t3.micro"
    qa   = "t3.small"
    prod = "t3.large"
  }
}

variable "extra_tags" {
  description = "Optional extra tags a caller can supply — merge() layers these onto the defaults."
  type        = map(string)
  default     = {}
}

variable "instance_name_override" {
  description = "Optional: force a specific Name tag. Leave null to auto-generate one (see coalesce() below)."
  type        = string
  default     = null
}
