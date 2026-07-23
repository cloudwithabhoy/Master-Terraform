# =============================================================================
# modules/eks/main.tf  —  The EKS cluster, its managed node group, the OIDC
# provider IRSA depends on, the two IRSA roles this project needs (backend
# pods, the AWS Load Balancer Controller), and the controller's Helm install.
#
# Why the IRSA roles live HERE and not in modules/iam: they need this
# module's own OIDC provider as their trust policy's principal — see
# modules/iam/main.tf's header comment for the full reasoning (avoiding a
# circular module dependency).
# -----------------------------------------------------------------------------
# This module needs the `helm` and `tls` providers in addition to `aws` —
# declared here so Terraform resolves them correctly, but (same convention as
# every other module) no actual `provider` configuration block: whatever
# calls this module supplies that.
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

# --- EKS cluster --------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    # Public access stays enabled deliberately — no bastion in this design
    # (see final-project/PROJECT.md's "Architecture decisions"), so `kubectl`
    # needs to reach the cluster's API endpoint directly from an operator's
    # laptop.
    endpoint_public_access = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-eks" })
}

# --- Managed node group ---------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-node-group" })

  # See modules/iam/outputs.tf: the node role's ARN exists before its policy
  # attachments finish — this depends_on closes that race explicitly rather
  # than relying on Terraform inferring it from the ARN string alone.
  depends_on = [var.node_role_policy_attachments]
}

# --- OIDC provider: what makes IRSA possible ---------------------------------
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, { Name = "${var.name_prefix}-eks-oidc" })
}

locals {
  oidc_provider_url_no_scheme = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

# --- IRSA role: backend pods --------------------------------------------------
data "aws_iam_policy_document" "backend_irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:sub"
      values   = ["system:serviceaccount:${var.backend_namespace}:${var.backend_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend_irsa" {
  name               = "${var.name_prefix}-backend-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.backend_irsa_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "backend_secrets_read" {
  statement {
    sid       = "AllowReadDbSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_policy" "backend_secrets_read" {
  name   = "${var.name_prefix}-backend-secrets-read"
  policy = data.aws_iam_policy_document.backend_secrets_read.json
}

resource "aws_iam_role_policy_attachment" "backend_secrets_read" {
  role       = aws_iam_role.backend_irsa.name
  policy_arn = aws_iam_policy.backend_secrets_read.arn
}

# --- IRSA role: AWS Load Balancer Controller ---------------------------------
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller_irsa" {
  name               = "${var.name_prefix}-alb-controller-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
  tags               = var.tags
}

# See policies/README.md — vendored from the upstream project, re-verify
# before applying against a real account.
resource "aws_iam_policy" "alb_controller" {
  name   = "${var.name_prefix}-alb-controller-policy"
  policy = file("${path.module}/policies/alb_controller_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller_irsa.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# --- AWS Load Balancer Controller: installed as cluster infrastructure ------
# The Helm chart creates its own ServiceAccount (serviceAccount.create=true)
# annotated with the IRSA role above — no separate kubernetes_service_account
# resource needed, and no `kubernetes` provider dependency for this piece,
# only `helm`.
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.alb_controller_chart_version

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_irsa.arn
  }

  depends_on = [aws_eks_node_group.this, aws_iam_role_policy_attachment.alb_controller]
}
