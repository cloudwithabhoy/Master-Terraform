# =============================================================================
# modules/rds/variables.tf  —  This module's public "API" (inputs)
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

variable "vpc_id" {
  description = "VPC to create the RDS security group in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Both private subnet IDs (one per AZ) — required for the DB subnet group even in single-AZ mode, and for prod's Multi-AZ standby placement."
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Backend tier's security group ID — the only source allowed to reach RDS on 5432."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class — sized per environment via .tfvars."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage, in GB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL major version — matches the postgres:16-alpine image in app/docker-compose.yml."
  type        = string
  default     = "16"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username — from modules/secrets, so the same generated credential is what's actually stored in Secrets Manager."
  type        = string
}

variable "master_password" {
  description = "Master password — from modules/secrets. Sensitive: never printed in plan/apply output."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable a Multi-AZ standby — true in prod only, per final-project/PROJECT.md's architecture decisions."
  type        = bool
  default     = false
}
