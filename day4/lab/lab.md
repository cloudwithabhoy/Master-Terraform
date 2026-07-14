# Day 4 — Shared Lab: An IAM Role, Built Under Explicit Version Constraints

**Goal:** Apply both of today's topics together — build a real IAM role + scoped S3-read policy
(Topic 2), while directly observing what `required_version`/`required_providers` actually do
(Topic 1): a lock file appears, and `terraform init -upgrade` re-resolves within your constraint.

> Cost: an S3 bucket, an IAM role, and an IAM policy are all free. Expect ~$0.

**Prerequisites:** [Topic 1 — Version Constraints](../1.%20version_constraints/version_constraints.md)
and [Topic 2 — IAM as Code](../2.%20iam_as_code/iam_as_code.md) both read first.

---

## The files in this folder

| File | What it does |
|------|--------------|
| `providers.tf` | AWS + random providers with explicit `~>` version constraints. |
| `variables.tf` | `project_prefix`, `environment` (validated), `owner_tag`. |
| `locals.tf` | `common_tags`, computed once, reused everywhere. |
| `main.tf` | A bucket, an IAM trust policy + role, a scoped S3-read-only permission policy, and the attachment. |
| `outputs.tf` | Bucket name, role ARN, policy ARN, account ID. |

Read the comments in each file before running.

---

## How to run the lab

### Step 0 — Move into this folder
```bash
cd day4/lab
```

### Step 1 — `terraform init`, then inspect what got resolved
```bash
terraform init
cat .terraform.lock.hcl
```
Look for the `version` line under the `hashicorp/aws` block — that's the exact version your
`~> 5.0` constraint resolved to, now locked. Expect: `Terraform has been successfully
initialized!`

### Step 2 — See the constraint in action
```bash
terraform providers
```
Prints every provider this config requires and the constraint governing it, straight from
`providers.tf`.

### Step 3 — Format and validate
```bash
terraform fmt
terraform validate
```

### Step 4 — Plan with the defaults
```bash
terraform plan
```
The summary should say:
```
Plan: 5 to add, 0 to change, 0 to destroy.
```
(The five: `random_id.suffix`, `aws_s3_bucket.app_data`, `aws_iam_role.app_role`,
`aws_iam_policy.s3_read_only`, `aws_iam_role_policy_attachment.attach_s3_read`. The `data.*`
blocks are data sources — marked `<=`, not counted here.)

### Step 5 — Trigger the validation block on purpose
```bash
terraform plan -var="environment=production"
```
Expect a validation error — `production` isn't in the allowed list (`dev`, `stage`, `prod`).

### Step 6 — Apply
```bash
terraform apply
```
Review the plan, type **`yes`**. Expect outputs like:
```
Outputs:

account_id  = "123456789012"
bucket_name = "master-terraform-day04-dev-a1b2c3d4"
policy_arn  = "arn:aws:iam::123456789012:policy/master-terraform-day04-dev-s3-read-only"
role_arn    = "arn:aws:iam::123456789012:role/master-terraform-day04-dev-role"
```

### Step 7 — Verify the IAM role in AWS
```bash
aws iam get-role --role-name "$(terraform output -raw role_arn | awk -F/ '{print $NF}')"
aws iam list-attached-role-policies --role-name "$(terraform output -raw role_arn | awk -F/ '{print $NF}')"
```
Confirm the trust policy shows `ec2.amazonaws.com` as the principal, and the attached policy
matches `policy_arn`.

### Step 8 — Deliberately re-resolve within the constraint
```bash
terraform init -upgrade
git diff .terraform.lock.hcl   # (if this were a real git repo checkpoint) — did anything change?
```
If AWS has shipped a newer 5.x release since your last `init`, the lock file's recorded version
bumps to it — still governed by the same `~> 5.0` constraint. This is the safe-upgrade loop from
`version_constraints.md` §7, run for real.

### Step 9 — Inspect state
```bash
terraform state list
```

### Step 10 — `terraform destroy`
```bash
terraform destroy
```
Type **`yes`**. Confirm the role is gone:
```bash
aws iam get-role --role-name "master-terraform-day04-dev-role" 2>&1 | grep -i "NoSuchEntity"
```

> Golden Rule: always leave the session with everything destroyed.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `Invalid value for variable` referencing your `validation` block | Read the `error_message` — it tells you exactly what's expected. Fix the `-var` value. |
| `Unsupported Terraform Core version` | Your installed Terraform CLI is older than `required_version`. Upgrade the CLI. |
| `EntityAlreadyExists` on the IAM role/policy name | Someone (or a previous run) already created it. Either `destroy` the old one or change `project_prefix`/`environment`. |
| `AccessDenied` creating IAM resources | Your Day 2 IAM user needs IAM permissions — confirm `AdministratorAccess` is still attached. |
| Plan shows a different resource count than expected | Make sure you're in `day4/lab/` and haven't already applied with different variable values. |

When the bucket, role, and policy are created, verified, and then destroyed, you've completed
Day 4. Move on to Day 5.
