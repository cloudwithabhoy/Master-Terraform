# main.tf  —  Setup check: create a small VPC

# --- Terraform + provider requirements ---------------------------------------
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x version # 5.0 - 5.10
    }
  }
}

# --- Configure the AWS provider ----------------------------------------------
provider "aws" {
  region = "us-east-1"
  # Credentials come from `aws configure` (~/.aws/credentials).
  # NEVER hard-code access keys here.
}

# --- A small VPC -------------------------------------------------------------
# A VPC is your own isolated network inside AWS. The only required setting is
# its IP address range (CIDR block). 10.0.0.0/16 gives ~65,000 addresses.
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name    = "master-terraform-day2-example"
    Course  = "Master Terraform"
    Purpose = "setup-check"
  }
}

# --- Output ------------------------------------------------------------------
# Printed after `apply`. If you see a real VPC id (like vpc-0abc123...),
# your whole setup works: Terraform ran, the provider downloaded, and your
# credentials created a real resource.
output "vpc_id" {
  description = "The ID of the VPC Terraform created"
  value       = aws_vpc.example.id
}
