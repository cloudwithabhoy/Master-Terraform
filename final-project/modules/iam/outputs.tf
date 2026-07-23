# =============================================================================
# modules/iam/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "cluster_role_arn" {
  description = "EKS cluster service role ARN — passed to modules/eks's cluster resource."
  value       = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  description = "EKS managed node group role ARN — passed to modules/eks's node group resource."
  value       = aws_iam_role.eks_node_group.arn
}

output "node_role_policy_attachments" {
  description = <<-EOT
    IDs of the node role's three policy attachments. A role's ARN (above) is
    available the instant the role exists — BEFORE its policy attachments
    finish — so passing only the ARN into modules/eks's node group wouldn't
    guarantee Terraform waits for the attachments too. environments/dev
    passes this list into modules/eks so its node group resource can
    `depends_on` it directly, closing that race.
  EOT
  value = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.eks_ecr_read_only.id,
  ]
}
