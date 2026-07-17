# =============================================================================
# modules/vpc/main.tf  —  A small, single-subnet VPC, callable per environment.
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration. Region-agnostic (looks up a valid AZ instead of
# hardcoding one) so this module works wherever it's called from.
#
# Deliberately minimal: just a VPC + one subnet — no Internet Gateway, no
# route table. This subnet has no path in/out to the internet; that's fine
# for what this lab is teaching (modules + .tfvars), and keeps the resource
# count small and easy to reason about.
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}


resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, { Name = "${var.name_prefix}-subnet" })
}
