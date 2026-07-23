# =============================================================================
# modules/eks/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "cluster_name" {
  description = "EKS cluster name — used by `aws eks update-kubeconfig` and k8s-deploy.yml."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Cluster API server endpoint — consumed by environments/dev's kubernetes/helm provider config."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA cert — consumed by environments/dev's kubernetes/helm provider config."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "The cluster's OIDC provider ARN — not needed elsewhere today (both IRSA roles this project needs already live in this module), exposed for completeness."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "backend_irsa_role_arn" {
  description = "Annotate the backend's Kubernetes ServiceAccount with this ARN (eks.amazonaws.com/role-arn) — see final-project/k8s/backend-deployment.yaml."
  value       = aws_iam_role.backend_irsa.arn
}

output "cluster_security_group_id" {
  description = <<-EOT
    EKS's automatically-created cluster security group ID — shared by the
    control plane and, absent a custom launch template, the node group's EC2
    instances too. There's no more per-tier "backend security group" now
    that the backend runs as a pod rather than its own EC2 instance, so
    modules/rds uses THIS as its ingress source instead — every pod on the
    node group's instances carries this security group.
  EOT
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
