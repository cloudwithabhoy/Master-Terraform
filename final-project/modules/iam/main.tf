# =============================================================================
# modules/iam/main.tf  —  Two "static" IAM roles EKS needs to even come into
# existence: the cluster's own service role, and the managed node group's
# instance role. Both are pure trust-policy + AWS-managed-policy roles with
# no dependency on the cluster itself — which is exactly why they live here
# and not in modules/eks: modules/eks needs these ARNs as INPUTS to create
# the cluster/node group in the first place.
#
# The two IRSA roles this project also needs (the backend's service account,
# and the AWS Load Balancer Controller's service account) live INSIDE
# modules/eks instead, not here — they depend on the cluster's OIDC provider,
# which only modules/eks creates. Wiring that dependency back into this
# module would make modules/iam and modules/eks depend on each other's
# outputs — a circular module dependency. Keeping OIDC-dependent roles inside
# modules/eks avoids that entirely (same reasoning as the alb<->compute
# cycle avoided during the earlier EC2 design — see git history).
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration.
# =============================================================================

# --- EKS cluster role --------------------------------------------------------
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS managed node group role ---------------------------------------------
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_group" {
  name               = "${var.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
  tags               = var.tags
}

# Standard trio of AWS-managed policies every EKS worker node needs:
#   - AmazonEKSWorkerNodePolicy: lets the node register/communicate with the
#     cluster's control plane.
#   - AmazonEKS_CNI_Policy: lets the VPC CNI plugin manage ENIs/IPs for pods.
#   - AmazonEC2ContainerRegistryReadOnly: lets the node pull images from ECR
#     (this project's frontend/backend images) — a NODE-level grant, since
#     the container runtime pulls images using the node's role, not a
#     per-pod role.
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read_only" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
