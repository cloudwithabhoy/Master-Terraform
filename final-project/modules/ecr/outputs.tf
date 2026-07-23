# =============================================================================
# modules/ecr/outputs.tf  —  This module's public "API" (outputs)
# =============================================================================

output "frontend_repository_url" {
  description = "Frontend ECR repository URL — used to build/push/pull the frontend image."
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_repository_url" {
  description = "Backend ECR repository URL — used to build/push/pull the backend image."
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_arn" {
  description = "Frontend ECR repository ARN — consumed by modules/iam to scope the frontend role's pull permissions."
  value       = aws_ecr_repository.frontend.arn
}

output "backend_repository_arn" {
  description = "Backend ECR repository ARN — consumed by modules/iam to scope the backend role's pull permissions."
  value       = aws_ecr_repository.backend.arn
}
