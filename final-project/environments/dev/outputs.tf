# =============================================================================
# outputs.tf  —  This root config's public "API" (outputs)
#
# No more bastion_public_ip/frontend_private_ip/backend_private_ip, and no
# more alb_dns_name from Terraform — the app's Ingress (not Terraform) is
# what causes the ALB to exist now. Once final-project/k8s/ingress.yaml is
# applied, get its address with:
#   kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# =============================================================================

output "eks_cluster_name" {
  description = "Pass to `aws eks update-kubeconfig --name <this> --region <region>` to configure kubectl."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The cluster's API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS host:port."
  value       = module.rds.endpoint
}

output "ecr_frontend_repository_url" {
  description = "Push the frontend image here (see app/README.md)."
  value       = module.ecr.frontend_repository_url
}

output "ecr_backend_repository_url" {
  description = "Push the backend image here (see app/README.md)."
  value       = module.ecr.backend_repository_url
}

output "backend_irsa_role_arn" {
  description = "Annotate final-project/k8s/backend-deployment.yaml's ServiceAccount with this ARN."
  value       = module.eks.backend_irsa_role_arn
}

output "db_secret_id" {
  description = "Secrets Manager secret name — the backend Deployment's DB_SECRET_NAME env var (see final-project/k8s/backend-deployment.yaml)."
  value       = module.secrets.secret_id
}
