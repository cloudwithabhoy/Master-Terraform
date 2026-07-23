# =============================================================================
# modules/rds/main.tf  —  RDS PostgreSQL, private subnets only, Multi-AZ
# conditional on the environment (prod only — see variables.tf's multi_az).
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration.
# =============================================================================

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-subnet-group" })
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allows Postgres (5432) only from the backend tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from the backend tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_security_group_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.master_username
  password          = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Teaching project, not a real production DB — skip the final snapshot and
  # deletion protection so `terraform destroy` (the Golden Rule) never gets
  # blocked waiting on either of them.
  skip_final_snapshot = true
  deletion_protection = false

  tags = merge(var.tags, { Name = "${var.name_prefix}-db" })
}
