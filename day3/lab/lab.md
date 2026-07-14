# Day 3 — Shared Lab: A Variable-Driven S3 Bucket + Object

**Goal:** Apply both of today's topics together — build a real S3 bucket and object entirely from
variables/locals/outputs, prove `validation` catches bad input, see a `sensitive` output get
hidden, read the plan, prove idempotency, inspect state, then destroy it.

> Cost: an empty S3 bucket and a tiny text object are effectively free, and we destroy them at the
> end. Expect ~$0.

**Prerequisites:** [Topic 1 — Variables](../1.%20variables/variables.md) and
[Topic 2 — First Resource](../2.%20first_resource/first_resource.md) both read first.

---

## The files in this folder

| File | What it does |
|------|--------------|
| `providers.tf` | Declares the AWS + random providers, region `us-east-1`. |
| `variables.tf` | `project_prefix`, `environment` (validated), `owner_tag`. |
| `locals.tf` | Computes `name_prefix` and `common_tags` once, for reuse everywhere. |
| `main.tf` | A random suffix, the S3 bucket, and a `hello.txt` object inside it. |
| `outputs.tf` | Bucket name, ARN, object key, and account ID. |

Read the comments in each file before running.

---

## How to run the lab

### Step 0 — Move into this folder
From the repository root:
```bash
cd day3/lab
```

### Step 1 — `terraform init`
```bash
terraform init
```
Downloads the AWS + random providers into `.terraform/` and writes a `.terraform.lock.hcl`.
Expect: `Terraform has been successfully initialized!`

### Step 2 — Format and validate (good habits)
```bash
terraform fmt        # tidies formatting (prints any file it changes)
terraform validate   # "Success! The configuration is valid."
```

### Step 3 — Plan with the defaults
```bash
terraform plan
```
Read it end to end. The summary should say:
```
Plan: 3 to add, 0 to change, 0 to destroy.
```
(The three: `random_id.suffix`, `aws_s3_bucket.example`, `aws_s3_object.hello`. The
`data.aws_caller_identity` block is a **data source** — it shows up marked `<=` for "read," not
`+` for "add," and doesn't count toward this total.) Notice fields marked `(known after apply)`.

### Step 4 — Trigger the validation block on purpose
```bash
terraform plan -var="environment=production"
```
Expect a validation error — `production` isn't in the allowed list (`dev`, `stage`, `prod`). This
is the `validation` block from `variables.tf` doing its job **before** anything touches AWS.

### Step 5 — Plan again with a valid override
```bash
terraform plan -var="environment=stage" -var="owner_tag=your-name-here"
```
Notice the bucket name and tags change to reflect `stage` — same code, different input.

### Step 6 — Apply with the defaults
```bash
terraform apply
```
Review the plan, type **`yes`**. Expect outputs like:
```
Outputs:

account_id  = "123456789012"
bucket_arn  = "arn:aws:s3:::master-terraform-day03-dev-a1b2c3d4"
bucket_name = "master-terraform-day03-dev-a1b2c3d4"
object_key  = "hello.txt"
```

### Step 7 — Confirm it exists, and read the object back
```bash
aws s3 ls | grep master-terraform-day03
aws s3 ls "s3://$(terraform output -raw bucket_name)/"
aws s3 cp "s3://$(terraform output -raw bucket_name)/hello.txt" -
```
You just built cloud storage and uploaded a file, entirely from code.

### Step 8 — Prove idempotency
```bash
terraform plan
```
It should say **`No changes. Your infrastructure matches the configuration.`**

### Step 9 — Inspect what Terraform tracks
```bash
terraform state list
terraform show
```
A `terraform.tfstate` file now exists here. Open it (JSON) but do **not** edit or commit it.

### Step 10 — `terraform destroy`
```bash
terraform destroy
```
Type **`yes`**. Terraform removes the object first, then the bucket. Confirm:
```bash
aws s3 ls | grep master-terraform-day03    # should print nothing
```

> Golden Rule: always leave the session with everything destroyed.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `Invalid value for variable` referencing your `validation` block | Read the `error_message` — it tells you exactly what's expected. Fix the `-var` value. |
| `BucketAlreadyExists` / `BucketAlreadyOwnedByYou` | Name is taken. Recreate the suffix: `terraform apply -replace=random_id.suffix`. |
| `Error: No valid credential sources found` | Run `aws configure`; confirm with `aws sts get-caller-identity`. |
| `AccessDenied` creating the bucket | Your IAM user needs S3 permissions — confirm `AdministratorAccess` (Day 2, step 3). |
| `BucketNotEmpty` on destroy | Only happens if objects exist outside Terraform's state. Here Terraform manages the object, so destroy works. |
| Plan shows other than "3 to add" | Make sure you're in `day3/lab/` and haven't already applied with different variable values. |

When the bucket + object are created, verified, and then destroyed, you've completed Day 3.
Move on to **[Day 4](../../day4/1.%20version_constraints/version_constraints.md)**.
