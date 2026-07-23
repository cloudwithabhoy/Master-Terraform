# =============================================================================
# modules/vpc/main.tf  —  2-AZ VPC: public subnets (ALB + NAT) and private
# subnets (EKS node group + RDS), one Internet Gateway, one NAT Gateway.
#
# Single NAT Gateway, not one per AZ — see final-project/PROJECT.md's cost
# section: a second NAT would roughly double that line item for a teaching
# project that doesn't need the extra availability it buys. This is also why
# there's only one private route table instead of one per AZ — both private
# subnets share the same (single) egress path.
#
# Subnets carry EKS-specific tags (kubernetes.io/cluster/<name>,
# kubernetes.io/role/elb or internal-elb) so the EKS cluster and the AWS
# Load Balancer Controller can auto-discover which subnets to use —
# see final-project/PROJECT.md's "core resources" section.
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration, so this module is region-agnostic.
# =============================================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# --- Public subnets: one per AZ — the ALB (via the Load Balancer Controller)
# spans both; the single NAT Gateway lives only in the first (index 0) -----
resource "aws_subnet" "public" {
  for_each = toset(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[index(var.availability_zones, each.value)]
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${each.value}"
    # EKS/ALB Controller subnet auto-discovery tags (see file header).
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  })
}

# --- Private subnets: one per AZ — the EKS node group + RDS primary live in
# the first AZ; the second AZ is used only for RDS's Multi-AZ standby (prod)
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[index(var.availability_zones, each.value)]
  availability_zone = each.value

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${each.value}"
    # EKS/ALB Controller subnet auto-discovery tags (see file header).
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  })
}

# --- NAT Gateway: single, in the first AZ's public subnet only ------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.availability_zones[0]].id
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat" })

  # NAT Gateway creation fails if the IGW isn't attached yet — Terraform's
  # dependency graph usually infers this via the subnet, but this relationship
  # is explicit enough (and important enough) to spell out (Day 6 Topic 3).
  depends_on = [aws_internet_gateway.this]
}

# --- Public route table: one, shared by both public subnets ---------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --- Private route table: one, shared by both private subnets — egress via
# the single NAT Gateway above ----------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-private-rt" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
