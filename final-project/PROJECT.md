# Final Project — 3-Tier Application on AWS, via Terraform + GitHub Actions

## Purpose

Every day so far taught one concept (or a handful) in isolation — a bucket here, an IAM role
there, a VPC as a teaching example. This project is different: it's **one real, cohesive
application's infrastructure**, built the way an actual team would build it — through pull
requests, automated plans, and gated deployments across **dev**, **qa**, and **prod** — instead of
someone running `terraform apply` by hand from their laptop.

The goal isn't to learn a new Terraform feature. It's to combine everything already learned
(modules, remote state, variables, `.tfvars` per environment, IAM, provider config) into the shape
a real production system actually takes, end to end.

---

## What we're building

A classic **3-tier architecture**, deployed on **Amazon EKS** (a deliberate pivot from an earlier
EC2-based design — see "Why EKS after all" below), using AWS services genuinely common in
industry for this exact pattern:

| Tier | Where it runs | Role |
|---|---|---|
| **Presentation** | Frontend pod(s) on EKS, exposed via a Kubernetes `Ingress` + the AWS Load Balancer Controller | Public entry point via an ALB the controller provisions automatically; the frontend pod is never directly internet-facing |
| **Application** | Backend pod(s) on EKS | Runs the app's business logic; only reachable from the frontend, over the cluster network |
| **Data** | RDS PostgreSQL (private subnet) | Persistent storage; only reachable from the EKS node group |

Both the frontend and backend run as **Docker containers pulled from ECR**, now scheduled by
Kubernetes instead of booted directly via EC2 `user_data`. The application itself (`app/`) is
unchanged — a deliberately minimal Flask frontend + backend, just enough to prove connectivity
through every tier, not a real product; see `app/README.md`. Nothing in the app's code changes for
this pivot: it already reads AWS credentials from its execution environment's default credential
chain, so IRSA (below) is a drop-in replacement for the EC2 instance profile it used before.

### Why EKS after all (pivoted back from the EC2 design)

The original plan (see git history / earlier revisions of this file) deliberately chose EC2 over
EKS specifically because the EKS control plane costs **~$73/month, running whether it's used or
not** — a real, continuous cost that doesn't disappear just by destroying app-level resources
between sessions. That tradeoff hasn't changed; **it's now been accepted deliberately** in exchange
for a more realistic, production-shaped Kubernetes deployment model. This is a genuine reversal,
not a refinement — see "Architecture decisions" below for the full list of what it changes.

**Practical consequence:** the "destroy at the end of every session" Golden Rule now matters more,
not less. Previously, forgetting to destroy meant risking the ALB/NAT sitting idle. Now, the EKS
control plane itself accrues cost every hour it exists, applied or not — **destroying the cluster
is the single highest-leverage cost action in this project.**

### Network design: security groups do most of the tier isolation; Kubernetes owns the rest

Same **two-subnet** shape as before — one **public** subnet (ALB + nothing else now; no more
bastion, see below) and one **private** subnet (the EKS node group and RDS). Tier isolation is
*mostly* enforced by security groups, with one honest simplification worth calling out:

- `sg-alb` (managed by the AWS Load Balancer Controller) → accepts `80` from the internet
- `sg-node-group` → shared by **every** pod on every node (frontend AND backend both run on the
  same node group) — accepts app traffic from `sg-alb`
- `sg-rds` → accepts `5432` only from `sg-node-group`

**The simplification:** unlike the EC2 design's crisp `sg-alb → sg-frontend → sg-backend → sg-rds`
chain, EKS pods on a shared node group share that node's security group by default — so at the
network layer, a compromised frontend pod could reach RDS through the same node group's security
group a backend pod uses. Real pod-level network isolation on EKS needs **Kubernetes
`NetworkPolicies`** (enforced by the CNI) or the more advanced "security groups for pods" feature —
genuinely worth knowing about, but **out of scope** for this project; noted here rather than left
as an unstated gap.

---

## The core resources

1. **VPC** — same 2-AZ, public+private subnet shape as before, Internet Gateway, one **NAT
   Gateway** — plus **EKS-required subnet tags** (`kubernetes.io/cluster/<name>` on both tiers,
   `kubernetes.io/role/elb`/`internal-elb` on public/private respectively) so the cluster and its
   Load Balancer Controller can discover them.
2. **EKS cluster + managed node group** (new — `modules/eks`) — the control plane, one managed
   node group (EC2 under the hood — see "Architecture decisions"), and the OIDC identity provider
   IRSA depends on.
3. **ECR** — unchanged: two repositories, `frontend` and `backend`.
4. **RDS PostgreSQL** — private subnet, ingress now scoped to the **node group's** security group
   (see the network-design simplification above); **Multi-AZ in `prod` only** (unchanged decision).
5. **Secrets Manager** — unchanged: stores the RDS credentials. Read access now granted via
   **IRSA** (an IAM role bound to a Kubernetes `ServiceAccount`) instead of an EC2 instance
   profile — the backend pod assumes this role automatically, no app code changes needed.
6. **IAM** — reworked for EKS: an EKS cluster role, a node group role (worker-node policies +
   ECR pull), an IRSA role for the backend's service account (Secrets Manager read, scoped to one
   secret ARN), and an IRSA role for the AWS Load Balancer Controller's service account.
7. **AWS Load Balancer Controller** (new — installed via Terraform's `helm_release`, part of
   `modules/eks`) — cluster *infrastructure*, not application code. Once installed, it watches for
   Kubernetes `Ingress` objects and provisions/manages an ALB automatically — Terraform never
   creates the ALB directly.
8. **App workloads** (frontend/backend `Deployment`s, `Service`s, and the `Ingress`) — **not**
   Terraform-managed (see "Architecture decisions" — the real-world Terraform/app split). These
   live as plain Kubernetes YAML in `final-project/k8s/`, applied via `kubectl` in their own
   CI/CD job, separate from `terraform apply`.

**Removed from the earlier EC2 design:** `modules/compute` (no more raw EC2 app instances —
Kubernetes schedules pods instead) and `modules/bastion` (see below — `kubectl`/IAM auth replaces
SSH as the access model). `modules/alb` as a directly-Terraform-managed load balancer is also
gone — the AWS Load Balancer Controller now owns that job.

(S3 + DynamoDB for Terraform's own remote state backend still exist — one bucket + one DynamoDB
table per environment, via `bootstrap/`, unchanged by this pivot.)

---

## ⚠️ Cost reality — read this before running anything

This pivot makes the project meaningfully more expensive than the EC2 version — read this
carefully before applying anything:

- **EKS control plane** — a flat **~$0.10/hour ≈ $73/month**, billed continuously the entire time
  the cluster exists, regardless of load or whether you're actively using it. This is now the
  **dominant cost** in the whole project, and the main reason destroying promptly matters more
  than ever.
- **Node group EC2 instances** — `t3.medium` (not the `t3.micro` used previously): EKS worker
  nodes need real headroom for system daemonsets (`kube-proxy`, the VPC CNI, CoreDNS, the ALB
  controller's own pods) on top of the app's pods — `t3.micro` risks pods failing to schedule at
  all. 1-2 nodes for `dev`, Free-Tier eligible only for the first 12 months and only on eligible
  instance types (`t3.medium` is **not** part of the EC2 Free Tier — another real cost increase).
- **RDS PostgreSQL** (`db.t3.micro`) — unchanged, Free-Tier eligible for 12 months in `dev`/`qa`;
  Multi-AZ in `prod` roughly doubles the instance-hour cost there.
- **ALB** (provisioned by the Load Balancer Controller once the app's `Ingress` is applied) — no
  free tier, roughly **$16-20/month** if left running, same as before — just created indirectly
  now instead of directly by Terraform.
- **NAT Gateway** — unchanged, ~$32/month + data transfer — the node group still needs egress to
  pull images from ECR and reach AWS APIs.
- **Secrets Manager** — unchanged, negligible.

**Always run `terraform destroy` immediately after a session — and confirm the EKS cluster itself
is gone, not just the app's pods.** Simply deleting the `Ingress`/`Deployment`s via `kubectl` stops
the ALB's cost, but the ~$73/month control-plane meter keeps running until `modules/eks`'s
resources are actually destroyed.

---

## Architecture decisions

Settled before any module code was written, so nothing below is an unconsidered default:

- **NAT Gateway, not VPC endpoints** — simpler to teach as one resource instead of several
  endpoints; accepted the wider outbound path and the extra ~$32/month for that simplicity.
- **ALB: HTTP only, no ACM/HTTPS** — no domain is registered for this project, and TLS termination
  isn't the concept this project is teaching. Revisit if a domain is ever added.
- **EC2 key pair referenced by name, not generated by Terraform** — retained from the earlier
  design for the node group's own SSH access if ever needed for deep debugging (not built into any
  workflow here); the private key material never enters Terraform state.
- **RDS Multi-AZ in `prod` only** — `dev`/`qa` stay single-AZ for cost; `prod` gets real failover.
- **One S3 bucket + one DynamoDB table per environment**, not one shared bucket for all three —
  stronger blast-radius isolation, at the cost of three bootstrap runs instead of one.
- **GitFlow-style long-lived branches (`dev` → `qa` → `main`), not trunk-based** — merging into
  `dev` applies `environments/dev`, merging `dev`→`qa` applies `environments/qa` (approval-gated),
  merging `qa`→`main` applies `environments/prod` (approval-gated). `main` doubles as the `prod`
  branch. The accepted cost is discipline: **only** fast-forward promotion merges flow
  `dev`→`qa`→`main`, no direct commits to `qa`/`main` outside that promotion PR.
- **EKS over EC2 (reversal)** — accepted the ~$73/month control-plane cost for a more
  production-realistic Kubernetes deployment model. See "Why EKS after all" above.
- **Managed Node Group, not Fargate** — closer to the EC2 mental model already built elsewhere in
  this course (still EC2 under the hood), at the cost of node-level sizing/patching being back in
  scope. Fargate would remove that, but also removes any EC2-level SSH story entirely.
- **AWS Load Balancer Controller + `Ingress`, not a directly-Terraform-managed ALB** — the
  EKS-native pattern: Terraform installs the controller (cluster infrastructure); the ALB itself
  gets created/managed by Kubernetes once an `Ingress` object exists. More real-world-correct for
  EKS, at the cost of a new Helm/Kubernetes-provider dependency inside Terraform.
- **Real-world Terraform/app split** — Terraform provisions the cluster, node group, IRSA roles,
  and the Load Balancer Controller (infrastructure). The frontend/backend `Deployment`s, `Service`s,
  and `Ingress` are plain Kubernetes YAML applied via `kubectl` in their own CI/CD job — **not**
  Terraform resources. This matches how most real organizations split "infra team owns Terraform"
  from "app team owns manifests," and keeps app deploys fast (no full `terraform plan`/`apply`
  cycle just to ship a new container tag). The alternative (Terraform manages everything, one
  `apply` produces a fully running app) is simpler to operate for a teaching project, but doesn't
  match how this is actually done at any real scale — deliberately chosen anyway, for realism.
- **Bastion host removed** — with EKS, `kubectl` access is IAM-authenticated (`aws eks
  update-kubeconfig` + the cluster's IAM auth), and pod-level debugging uses `kubectl exec`/`kubectl
  logs` — there's no SSH-shaped access gap left for a bastion to fill. This also means the EKS
  cluster's API endpoint stays on its default (public **and** private) access mode, so `kubectl`
  works directly from an operator's laptop without a VPN or jump host.
- **Node group sizing** — `min=1`, `desired=1`, `max=2` for `dev` (cost-conscious default;
  `qa`/`prod` can size up via their own `.tfvars` once those environments are built).

---

## The plan — building this in phases

> **Rule: every `apply`, in every environment — including `dev`'s very first one — happens through
> the pipeline, never from a laptop.** The **only** exception is the `bootstrap/` configs: they
> create the state backend the pipeline itself depends on, so they're inherently a one-time,
> local-state, out-of-band step (Day 8 Topic 1 §4). Local `terraform plan`/`validate`/`fmt` while
> authoring code is fine; local `terraform apply` against `dev`/`qa`/`prod` is not, ever. The app's
> Kubernetes manifests (`kubectl apply`) follow the same rule, just via their own CI/CD job instead
> of `terraform-apply.yml` — see phase 6 below.

1. **Bootstrap the remote state backend for `dev`** — a small, local-state `bootstrap/dev/` config
   creating just `dev`'s S3 bucket + DynamoDB table. The one deliberate exception to the rule above.
2. **Author the modules** (`modules/vpc`, `modules/ecr`, `modules/eks`, `modules/rds`,
   `modules/secrets`, `modules/iam`) — each self-contained, callable with different inputs per
   environment. `modules/compute`, `modules/bastion`, and `modules/alb` from the earlier EC2 design
   are retired (see "The core resources" above for why).
3. **Author `environments/dev`** — one root config calling all the modules with `dev`-sized inputs,
   backend-configured against phase 1's bucket/table, plus the `kubernetes`/`helm` provider
   configuration needed for the Load Balancer Controller's `helm_release`. Validate locally with
   `terraform init`/`validate`/`plan` only — **no local `apply`**.
4. **Author the app's Kubernetes manifests** (`final-project/k8s/`) — frontend/backend
   `Deployment`s + `Service`s, and one `Ingress` wired to the frontend's `Service`, annotated for the
   AWS Load Balancer Controller.
5. **Create the `dev`/`qa` branches and build the GitHub Actions workflows** — same branch-aware
   `terraform-plan.yml`/`terraform-apply.yml` as before, **plus a new `k8s-deploy.yml`** that runs
   `kubectl apply` against `final-project/k8s/` — triggered separately from the Terraform workflows
   (see "Architecture decisions" — the real-world Terraform/app split), gated the same way
   (`dev` auto-applies, `qa`/`prod` need approval).
6. **Open the first PR into `dev`** — `terraform-plan.yml`/`terraform-apply.yml` stand up the VPC,
   EKS cluster, node group, and Load Balancer Controller for the first time; once the cluster
   exists, `k8s-deploy.yml` applies the app manifests on top of it.
7. **Add the approval gate for `qa`/`prod`** — unchanged from the EC2-era plan: GitHub Environments'
   required reviewers, applied to both the Terraform and `k8s-deploy.yml` jobs.
8. **Replicate `dev`'s config into `qa` and `prod`** — their own `bootstrap/qa`/`bootstrap/prod`
   runs, then the same PR → plan → approve → merge → apply flow for both the infrastructure and the
   app manifests.

---

## How the pieces fit together (the mental model)

**Traffic flow:**
```
Internet
   │
   ▼
ALB (public subnet — created/managed by the AWS Load Balancer Controller, not Terraform directly)
   │
   ▼
Ingress -> Frontend Service -> Frontend pod(s) (EKS node group, private subnet)
   │
   ▼
Backend Service -> Backend pod(s) (same node group) — reads DB creds via IRSA + Secrets Manager
   │
   ▼
RDS PostgreSQL (private subnet)
```

**Cluster access flow (operator debugging — no bastion, no SSH):**
```
Your laptop
   │
   ▼
aws eks update-kubeconfig  (IAM-authenticated — uses your existing AWS credentials)
   │
   ▼
kubectl exec / kubectl logs / kubectl port-forward — directly against pods, no jump host
```

**CI/CD flow — branch-per-environment promotion (`dev` → `qa` → `main`/prod), now with a second,
independent pipeline for app deploys:**
```
feature branch
     │
     ▼
  PR → dev branch
     │   terraform-plan.yml  → plans environments/dev (cluster/infra changes only)
     │   k8s-deploy.yml (plan/diff mode) → shows what would change in final-project/k8s/
     ▼
  human reviews both, merges
     │
     ▼
  terraform-apply.yml → applies environments/dev infra AUTOMATICALLY (no gate)
  k8s-deploy.yml       → applies final-project/k8s/ manifests AUTOMATICALLY (no gate)
     │
     ▼
  PR: dev → qa branch, then qa → main   (same promotion pattern as before, both pipelines
                                          gated on their respective qa/prod GitHub Environment
                                          approval — see "Architecture decisions")
```

Both Terraform workflows still key off the PR's **target branch** to decide which
`environments/*` folder to act on. `k8s-deploy.yml` follows the identical branch→environment
mapping, but points `kubectl` at that environment's EKS cluster instead of running Terraform.

**Discipline this model requires:** unchanged from before — `qa` and `main` only ever move forward
via a promotion PR from the branch below them, for **both** pipelines.

Nobody runs `terraform apply` or `kubectl apply` against any environment from a laptop — every
change, infra or app, is visible as a reviewed diff before it ever touches real infrastructure. The
sole exception is `bootstrap/`, which by necessity runs locally once per environment.

---

## Folder structure

```
Master-Terraform/                      ← repo root
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml         ← runs on PRs targeting dev/qa/main, branch→folder mapped
│       ├── terraform-apply.yml        ← runs on merge to dev/qa/main; qa/main gated on approval
│       └── k8s-deploy.yml             ← NEW: applies final-project/k8s/ against the target
│                                          environment's EKS cluster; same branch→env mapping and
│                                          approval gating, but independent of the Terraform runs
└── final-project/
    ├── PROJECT.md                     ← this file
    ├── app/
    │   ├── README.md                  ← how to test locally, how to push to ECR
    │   ├── docker-compose.yml         ← local test rig: db + backend + frontend
    │   ├── backend/                   ← Flask: reads Secrets Manager, talks to Postgres
    │   └── frontend/                  ← Flask: calls the backend, renders the result
    ├── k8s/                           ← NEW: plain Kubernetes YAML, NOT Terraform-managed
    │   ├── frontend-deployment.yaml
    │   ├── frontend-service.yaml
    │   ├── backend-deployment.yaml
    │   ├── backend-service.yaml
    │   └── ingress.yaml               ← annotated for the AWS Load Balancer Controller
    ├── modules/
    │   ├── vpc/
    │   ├── ecr/
    │   ├── eks/                       ← NEW: cluster + managed node group + OIDC + ALB controller
    │   ├── rds/
    │   ├── secrets/
    │   └── iam/
    ├── bootstrap/                     ← unchanged — local-state, run once per environment
    │   ├── dev/
    │   ├── qa/
    │   └── prod/
    └── environments/
        ├── dev/
        ├── qa/
        └── prod/
```

---

## Status

- **Application: written.** A minimal Flask frontend + backend (`app/`), unchanged by this pivot —
  see `app/README.md`.
- **Architecture: re-finalized around EKS.** Every decision above (EKS over EC2, managed node
  group, Load Balancer Controller + Ingress, the real-world Terraform/app split, bastion removed)
  is deliberate — see "Architecture decisions."
- **Infrastructure: mid-rebuild.** The earlier EC2-based modules (`vpc`, `iam`, `ecr`, `secrets`,
  `rds`, plus `environments/dev`, `bootstrap/dev` not yet started, and the CI/CD workflow shells)
  were built before this pivot and are being reworked: `vpc` needs EKS subnet tags, `iam` needs
  IRSA roles instead of EC2 instance profiles, `secrets`/`ecr`/`rds` are largely unaffected,
  `environments/dev` needs the new `modules/eks` wired in and the old `compute`/`bastion`/`alb`
  module calls removed. `modules/compute`, `modules/bastion`, and `modules/alb` themselves are
  retired outright, not reworked.

This file will be updated as each phase in "The plan" above is completed.
