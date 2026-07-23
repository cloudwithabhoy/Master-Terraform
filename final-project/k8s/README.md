# `final-project/k8s/` — the app's Kubernetes manifests

**Not Terraform-managed** — see `PROJECT.md`'s "Architecture decisions" (the real-world
Terraform/app split). Terraform provisions the EKS cluster, node group, IRSA roles, and the AWS
Load Balancer Controller (`modules/eks`). Everything in this folder is plain Kubernetes YAML,
applied via `kubectl apply` in its own CI/CD job (`k8s-deploy.yml`), separate from
`terraform apply`.

## The `${...}` placeholders

A few values here can only be known *after* Terraform has applied (an ECR repository URL, an
IRSA role's ARN, a Secrets Manager secret's name) — they're written as shell-style
`${PLACEHOLDER}` placeholders and substituted by `envsubst` in `k8s-deploy.yml` immediately before
`kubectl apply`, using values read straight from `terraform output`:

| Placeholder | Comes from (`terraform output …`) |
|---|---|
| `${FRONTEND_ECR_REPOSITORY_URL}` | `ecr_frontend_repository_url` |
| `${BACKEND_ECR_REPOSITORY_URL}` | `ecr_backend_repository_url` |
| `${BACKEND_IRSA_ROLE_ARN}` | `backend_irsa_role_arn` |
| `${DB_SECRET_NAME}` | `db_secret_id` |
| `${AWS_REGION}` | this course's fixed region, `us-east-1` |

If you ever apply these manually instead of through CI, run `envsubst` yourself first — applying
the raw files with literal `${...}` text in them will fail or (worse) silently create resources
with garbage values.

## What's here

- `backend-deployment.yaml` — the backend's `ServiceAccount` (IRSA-annotated) + `Deployment`
- `backend-service.yaml` — in-cluster `ClusterIP` Service the frontend calls
- `frontend-deployment.yaml` — the frontend's `Deployment` (no ServiceAccount/IRSA needed — it
  makes no AWS API calls of its own)
- `frontend-service.yaml` — in-cluster `ClusterIP` Service the `Ingress` targets
- `ingress.yaml` — the public entry point, annotated for the AWS Load Balancer Controller
  (`modules/eks` installs the controller; this `Ingress` is what makes it actually provision an ALB)

## Deploy order

`kubectl apply -f final-project/k8s/` applies all five in one shot — Kubernetes doesn't require a
particular file order (unlike Terraform's dependency graph, object references here resolve at
runtime, e.g. the `Ingress`'s backend `Service` name just needs to exist by the time the
controller reconciles it, not at apply time).
