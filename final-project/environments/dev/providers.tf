# =============================================================================
# providers.tf  —  Provider requirements + the S3 backend for dev's state,
# plus the helm provider that talks to THIS environment's EKS cluster.
# -----------------------------------------------------------------------------
# The bucket/table below must already exist — created once by bootstrap/dev
# (Day 8 Topic 1 §4's bootstrap pattern), NOT by this config. Backend blocks
# can't reference variables, so these values are literal on purpose; keep
# them in sync with bootstrap/dev if either ever changes.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "master-terraform-final-project-dev-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "master-terraform-final-project-dev-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Helm provider: configured to talk to THIS environment's EKS cluster ---
# Needs the cluster to already exist to authenticate against it — a known
# EKS+Terraform limitation. In practice this works in a single `terraform
# apply` because module.eks's outputs become known partway through that same
# apply (Terraform builds the graph so the cluster is created before
# anything depending on these values). If a completely fresh `apply` ever
# errors with something like "Invalid provider configuration," re-run
# `terraform apply` a second time — the cluster will already exist by then.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
