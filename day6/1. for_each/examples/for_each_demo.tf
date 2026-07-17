# =============================================================================
# for_each_demo.tf  —  Illustrative only (matches for_each.md §2)
# -----------------------------------------------------------------------------
# NOT free like the S3 examples elsewhere in this course — this creates REAL
# EC2 instances (billed per hour while running). Run `terraform destroy`
# immediately after you're done looking at the plan/apply output.
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_ami" "amazon_linux" { # DATA SOURCE: read-only lookup, creates nothing in AWS
  most_recent = true            # Many AMIs will match the filter below — take only the newest
  owners      = ["amazon"]      # Only search AMIs Amazon itself publishes, not random public ones

  filter {                                    # One matching rule for the search
    name   = "name"                           # Match against the AMI's "name" field
    values = ["al2023-ami-*-x86_64"]          # Pattern: Amazon Linux 2023, any version (*), 64-bit
  }
}

# Real, valid AZs for whatever region you're in — no hardcoded IP/CIDR needed.
data "aws_availability_zones" "available" {
  state = "available"
}

# --- for_each over a MAP: each.key AND each.value are both meaningful --------
variable "servers" {                # A MAP: server name => instance size
  type = map(string)                 # Each value must be a string (an instance type)
  default = {
    frontend = "t2.micro"             # Key "frontend", value "t2.micro"  — light, just serves static/API traffic
    #backend  = "t2.small"             # Key "backend", value "t2.small"   — runs the app logic, needs more headroom
    database = "t2.medium"            # Key "database", value "t2.medium" — heaviest workload, most CPU/RAM
  }
}

# every server always gets its own fixed AZ no matter what else changes.
locals {
  server_azs = {
    frontend = data.aws_availability_zones.available.names[1] # was [0] — that AZ was slow/stuck on capacity, reusing backend's AZ instead
    backend  = data.aws_availability_zones.available.names[1]
    database = data.aws_availability_zones.available.names[2]
  }
}

resource "aws_instance" "server" {   # One EC2 instance per entry in var.servers
  for_each = var.servers              # Loop once per map entry — 3 entries, 3 instances

  ami               = data.aws_ami.amazon_linux.id # Every instance boots from the same looked-up AMI
  instance_type     = each.value                   # THIS entry's value, e.g. "t2.micro"
  availability_zone = local.server_azs[each.key]    # THIS entry's fixed AZ, looked up by key

  tags = {
    Name = each.key                  # THIS entry's key, e.g. "frontend" — becomes the instance's Name tag
  }
}

# Try this experiment — the direct opposite of count_demo.tf's result:
#   1. terraform apply
#      -> frontend, backend, database all created, each in its own fixed AZ
#   2. Remove "backend" (the MIDDLE entry, alphabetically or not — position
#      never mattered here) from var.servers above
#   3. terraform plan
#   4. Notice ONLY aws_instance.server["backend"] is destroyed. "frontend" and
#      "database" show ZERO changes — no Modifying, no destroy, nothing —
#      because for_each addresses instances by KEY, and neither of their keys
#      moved. Compare this directly against count_demo.tf, where removing one
#      middle entry destroyed TWO real servers.


