# Day 5 — Shared Lab: One VPC Module, Deployed to `dev` and `qa`

**Goal:** Apply both of today's topics together — a project laid out per Topic 1's conventions,
with a single **VPC module** (`modules/vpc/`) called once and deployed to two different
environments via real `.tfvars` files (Topic 2). The module's code never changes between
environments — only the CIDR block (and other inputs) you pass via `-var-file` do.

> **A quick heads-up:** this lab previews an idea this course doesn't formally teach until Day 9
> — **modules**. You don't need to understand every line of `modules/vpc/main.tf` yet; treat it
> as "a small reusable network," and focus on what Topics 1-2 are actually about: the module's
> inputs changing per environment via `.tfvars`.

> Cost: a VPC and one subnet are both free. Expect ~$0.

**Prerequisites:** Both of today's topics
([1](../1.%20project_structure/project_structure.md), [2](../2.%20terraform_tfvars/terraform_tfvars.md))
read first.

---

## The files in this folder

| File | What it does |
|------|--------------|
| `providers.tf` | AWS provider. |
| `variables.tf` | `project_prefix`, `owner_tag`, `vpc_cidr` (default), `environment` (**required**, no default, only `dev`/`qa` allowed). |
| `locals.tf` | `name_prefix`, `common_tags`. |
| `main.tf` | One call to `module "vpc"`. |
| `modules/vpc/` | The reusable module: a VPC and one subnet (region-agnostic AZ lookup) — nothing more. |
| `outputs.tf` | VPC ID, the CIDR actually used, subnet ID, and the environment targeted. |
| `environments/dev.tfvars` / `qa.tfvars` | Real, gitignored per-environment values — `dev` (`10.0.0.0/16`), `qa` (`10.1.0.0/16`). |

---

## How to run the lab

### Step 0 — Move into this folder
```bash
cd day5/lab
```

### Step 1 — Check your `.tfvars` files
`environments/dev.tfvars` and `environments/qa.tfvars` already exist in this folder — open each
and set `owner_tag` to your name if you'd like. These are real, gitignored files (unlike most of
this repo, they're **not** committed to git — confirm with `git status` that they don't show up
as tracked or stageable).

### Step 2 — `terraform init`
```bash
terraform init
```

### Step 3 — Plan against `dev`
```bash
terraform plan -var-file="environments/dev.tfvars"
```
Summary should say:
```
Plan: 2 to add, 0 to change, 0 to destroy.
```
(The module creates exactly two resources: the VPC and the subnet.
`data.aws_availability_zones` is a data source, not counted here.)

### Step 4 — Try planning with NO `-var-file`
```bash
terraform plan
```
Terraform **prompts you interactively** for `environment` — it has no default on purpose. Press
Ctrl+C to cancel rather than typing a value here; this is the required-variable behavior from
Day 3 Topic 1, now protecting you from accidentally deploying into the wrong environment.

### Step 5 — Apply `dev`
```bash
terraform apply -var-file="environments/dev.tfvars"
```
Type **`yes`**. Expect outputs like:
```
Outputs:

environment   = "dev"
subnet_id     = "subnet-0abc123..."
vpc_cidr_used = "10.0.0.0/16"
vpc_id        = "vpc-0abc123..."
```

### Step 6 — Verify it in AWS
```bash
aws ec2 describe-vpcs --vpc-ids "$(terraform output -raw vpc_id)"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"
```

### Step 7 — Destroy `dev` before moving on
```bash
terraform destroy -var-file="environments/dev.tfvars"
```
Type **`yes`**. Always pass the same `-var-file` to `destroy` that you used to `apply` — Terraform
needs it to compute the same resource addresses.

### Step 8 — Repeat for `qa`
```bash
terraform apply -var-file="environments/qa.tfvars"
```
Confirm via the outputs that `vpc_cidr_used` is now `10.1.0.0/16` (from `qa.tfvars`), not
`10.0.0.0/16` — same module, same code, a different input produced a genuinely different network.
Verify as in Step 6, then:
```bash
terraform destroy -var-file="environments/qa.tfvars"
```

**What just happened, step by step** (nothing in any `variables.tf` was ever edited — Terraform
just resolves `var.vpc_cidr` fresh every run, checking the precedence order
`-var` → `-var-file` → `*.auto.tfvars` → env var → `default`, top to bottom, and stopping at the
first one that supplies a value):

1. `qa.tfvars` supplies `vpc_cidr = "10.1.0.0/16"`.
2. For **this run only**, the root's `var.vpc_cidr` resolves to `"10.1.0.0/16"` (its `default`
   is skipped, not touched).
3. Root `main.tf`'s `module "vpc" { vpc_cidr = var.vpc_cidr }` passes that resolved value into
   the module.
4. The module's own `var.vpc_cidr` resolves to `"10.1.0.0/16"` too (its own `default` also
   skipped, also untouched).
5. `modules/vpc/main.tf`'s `cidr_block = var.vpc_cidr` picks up `"10.1.0.0/16"` — that's the
   real CIDR block AWS creates.

Run `terraform apply -var-file="environments/dev.tfvars"` again afterward, and you'd get
`10.0.0.0/16` right back — proof nothing was permanently "changed," it's resolved fresh every
single run.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `environment must be one of: dev, qa` | Check the `environment` value inside the `.tfvars` file you're passing. |
| Prompted for `environment` unexpectedly | You forgot `-var-file="environments/<env>.tfvars"` on this command. |
| `destroy` says "No changes. No objects need to be destroyed" but you expected a VPC | You likely used a different `-var-file` (or none) than the one used to `apply` — resource names/addresses are computed from `environment`, so Terraform is looking in the wrong place. |
| `AccessDenied` creating VPC resources | Confirm your Day 2 IAM user still has `AdministratorAccess`. |
| `DependencyViolation` on destroy | Make sure nothing outside this Terraform state (e.g. something created manually in the console) still references this VPC. |

When both `dev` and `qa` have been applied, verified, and destroyed, you've completed Day 5. Move
on to **Day 6**.
