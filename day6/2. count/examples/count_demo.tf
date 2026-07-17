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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Real, valid AZs for whatever region you're in — no hardcoded IP/CIDR needed.
data "aws_availability_zones" "available" {
  state = "available"
}

variable "servers" {
  type    = list(string)
  default = ["frontend", "database"]
}

# Tied to each NAME, not to a position — this is what makes the demo below
# work. If AZ were just data.aws_availability_zones.available.names[count.index],
# it would shift right along with the name when the list changes, and nothing
# would ever conflict. Keying by name instead means "database" always wants
# its OWN az no matter which slot it ends up in.
locals {
  server_azs = {
    frontend = data.aws_availability_zones.available.names[1]
    backend  = data.aws_availability_zones.available.names[1]
    database = data.aws_availability_zones.available.names[2]
  }
}

resource "aws_instance" "server" {
  count = length(var.servers)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  # availability_zone can't be changed in place. Looked up by this instance's
  # NAME (not its index), so if "database" ever ends up sitting in a slot that
  # previously belonged to a different name, its required AZ won't match what's
  # already there — forcing a real destroy + recreate, not just a tag update.
  availability_zone = local.server_azs[var.servers[count.index]]

  tags = {
    Name = var.servers[count.index]
  }
}

output "server_names" {
  value = aws_instance.server[*].tags.Name
}

# Try this experiment:
#   1. terraform apply
#      -> frontend = AZ[0], backend = AZ[1], database = AZ[2]
#   2. Remove "backend" (the MIDDLE entry) from var.servers above, so it
#      reads ["frontend", "database"]
#   3. terraform plan
#   4. Notice server[1] is destroyed AND recreated: it used to be "backend"
#      (in AZ[1]), and is now "database" trying to take that same slot — but
#      "database" already existed at server[2] in AZ[2], so THAT instance is
#      destroyed too. Removing one middle item destroyed two real servers,
#      not one.
