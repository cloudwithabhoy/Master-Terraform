# =============================================================================
# modules/eks/variables.tf  —  This module's public "API" (inputs)
# =============================================================================

variable "name_prefix" {
  description = "Prefix applied to every resource name/tag this module creates."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to every resource (merged in, not overwritten)."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "Region the cluster runs in — passed to the AWS Load Balancer Controller's Helm values."
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster and its Load Balancer Controller operate in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Both public subnet IDs — where the ALB (managed by the Load Balancer Controller) gets provisioned."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Both private subnet IDs — where the managed node group's instances launch."
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "EKS cluster service role ARN, from modules/iam."
  type        = string
}

variable "node_role_arn" {
  description = "EKS managed node group role ARN, from modules/iam."
  type        = string
}

variable "node_role_policy_attachments" {
  description = "Opaque list from modules/iam (its policy-attachment IDs) — referenced via depends_on so the node group waits for the node role's policies to actually finish attaching before nodes try to join (see modules/iam/outputs.tf)."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group. t3.medium, not t3.micro — EKS worker nodes need headroom for system daemonsets (kube-proxy, VPC CNI, CoreDNS, the ALB controller's own pods) on top of app pods (see final-project/PROJECT.md's cost section)."
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "Node group minimum size."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Node group maximum size."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Node group desired size."
  type        = number
  default     = 1
}

variable "db_secret_arn" {
  description = "Secrets Manager secret ARN (from modules/secrets) — scopes the backend IRSA role's read permission to this one secret."
  type        = string
}

variable "backend_namespace" {
  description = "Kubernetes namespace the backend's ServiceAccount lives in — must match final-project/k8s/backend-deployment.yaml exactly, or IRSA's trust condition won't match."
  type        = string
  default     = "default"
}

variable "backend_service_account_name" {
  description = "Name of the backend's Kubernetes ServiceAccount — must match final-project/k8s/backend-deployment.yaml exactly, or IRSA's trust condition won't match."
  type        = string
  default     = "backend"
}

variable "alb_controller_chart_version" {
  description = "aws-load-balancer-controller Helm chart version. Pinned deliberately (Day 4's version-constraints lesson, applied to Helm charts too) — check https://github.com/aws/eks-charts/releases before bumping."
  type        = string
  default     = "1.8.1"
}
