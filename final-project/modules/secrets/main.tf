# =============================================================================
# modules/secrets/main.tf  —  Generates the RDS master password and creates
# the Secrets Manager secret CONTAINER that will hold the full DB connection
# info.
#
# This module deliberately does NOT create the secret's VALUE (an
# aws_secretsmanager_secret_version) — that happens once, in
# environments/dev/main.tf, after modules/rds exists. Why: the final secret
# value needs the RDS endpoint (host/port), but RDS itself needs THIS
# module's generated username/password to be created with. Wiring the value
# here would make modules/secrets and modules/rds depend on each other's
# outputs — a circular module dependency Terraform can't resolve. Splitting
# "generate the credential" (here, no RDS dependency) from "store the final
# value" (root config, after RDS exists) breaks that cycle.
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration.
# =============================================================================

resource "random_password" "db" {
  length  = 20
  special = true
  # RDS master passwords can't contain '/', '@', '"', or a space (AWS API
  # constraint) — excluded from the special-character set below.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.name_prefix}-db-credentials"

  # Secrets Manager defaults to a 30-day recovery window before a deleted
  # secret's NAME can be reused — that fights the course's "destroy at the
  # end of every session" habit (a same-day re-apply would fail to recreate
  # a secret with the same name). 0 = delete immediately, no recovery window.
  recovery_window_in_days = 0

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-credentials" })
}
