# =============================================================================
# modules/ecr/main.tf  —  Two ECR repositories (frontend, backend), each with
# vulnerability scanning on push and a lifecycle policy so old images don't
# quietly accumulate storage cost forever.
# -----------------------------------------------------------------------------
# No `provider` block here on purpose — whatever calls this module supplies
# the provider configuration.
# =============================================================================

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.name_prefix}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Lets `terraform destroy` remove this repo even if it still has images in
  # it — without this, destroy fails on a non-empty repo, fighting the
  # course's "always destroy at the end of every session" golden rule.
  force_delete = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend-ecr" })
}

resource "aws_ecr_repository" "backend" {
  name                 = "${var.name_prefix}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-ecr" })
}

# --- Lifecycle policy: same rules for both repos — expire untagged images
# after 7 days, and once a repo holds more than 10 images total, expire the
# oldest ones beyond that count -------------------------------------------
locals {
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = local.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy     = local.lifecycle_policy
}
