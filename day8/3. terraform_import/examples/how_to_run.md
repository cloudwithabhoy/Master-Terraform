# How to Run This Example

**Goal:** Starting from a real, already-managed codebase (`main.tf`), bring an EC2 instance that
was launched by hand — completely outside Terraform — under Terraform's management, without
destroying and recreating it, and without touching the infrastructure you already had.

> Cost: one small S3 bucket (free) + one `t2.micro`/`t3.micro` instance (Free-Tier eligible).
> Destroy promptly when done.

---

## Step 0 — Move into this folder

```bash
cd "day8/3. terraform_import/examples"
terraform init
```

---

## Step 1 — Apply your EXISTING infrastructure first

```bash
terraform apply
```
Type **`yes`**. This creates just `aws_s3_bucket.app_logs` from `main.tf` — your team's real,
already-managed infrastructure, unrelated to the import you're about to do. This step matters:
it makes the rest of this walkthrough realistic instead of starting from an empty folder.

---

## Step 2 — Launch an EC2 instance by hand, outside Terraform

Pick **either** option below — both produce the exact same real-world result, so only do one.

**Option A — Actually click through the AWS Console:**
1. Sign in to the [AWS Console](https://console.aws.amazon.com/) and open the **EC2** service.
2. Click **Launch instance**.
3. Give it a name, e.g. `hand-launched-instance`.
4. Under **Application and OS Images**, leave the default Amazon Linux AMI selected.
5. Under **Instance type**, pick `t2.micro` (or `t3.micro`).
6. Leave everything else at its defaults.
7. Click **Launch instance**.
8. Once it shows as **Running**, copy its **Instance ID** (looks like `i-0abcdef1234567890`) from
   the instances list — you'll need it in Step 3.

**Option B — The CLI equivalent** (faster, same effect, no browser needed):
```bash
AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query "reverse(sort_by(Images, &CreationDate))[0].ImageId" --output text)

aws ec2 run-instances --image-id "$AMI_ID" --instance-type t2.micro --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=hand-launched-instance}]' \
  --query "Instances[0].InstanceId" --output text
```
Note the instance ID it prints.

Either way: as far as Terraform is concerned right now, this instance doesn't exist — no `.tf`
code, no state entry — even though `main.tf`'s bucket, right next to it, is fully managed. Exactly
the mixed reality `terraform import` exists for.

---

## Step 3 — Declare the import, alongside your existing resource

Open `import.tf` and replace `"i-replace-with-a-real-id"` with the real instance ID
from Step 2:

```hcl
import {
  to = aws_instance.legacy
  id = "i-0abcdef1234567890"   # <- your real instance ID
}
```

This file sits in the **same folder** as `main.tf` — Terraform loads both together. You're adding
one resource to an already-real config, not starting fresh.

---

## Step 4 — Generate the matching resource block

```bash
terraform plan -generate-config-out="generated.tf"
```

Look at the plan summary closely: it should show the EC2 instance being **imported**, and
`aws_s3_bucket.app_logs` showing **no changes at all** — proof that adding an import doesn't touch
infrastructure you already had. Terraform also writes a best-effort
`resource "aws_instance" "legacy" { ... }` block into `generated.tf`. **Review it carefully** —
generated code is a strong starting point, not guaranteed perfect.

---

## Step 5 — Move the generated code in, then apply

Move (or merge) `generated.tf`'s content into `import.tf`, in place of the "don't write
this by hand" comment. Then:

```bash
terraform plan
```
Expect **`No changes`** — if you see a diff, resolve it before continuing; it means the generated
code doesn't exactly match reality yet.

```bash
terraform apply
```
Type **`yes`**. This finalizes the import — the instance is now fully Terraform-managed, with no
downtime and no new instance ID, sitting right alongside your pre-existing bucket in the same
state file.

---

## Step 6 — Remove the `import` block

The `import` block only needs to exist for one `apply` — it's a one-time migration instruction,
not a permanent part of your configuration. Delete it now that the instance is imported.

```bash
terraform plan
```
Expect **`No changes`** — removing the `import` block doesn't change any real infrastructure, it
just stops Terraform from re-declaring an import that already happened.

---

## Step 7 — Destroy

```bash
terraform destroy
```
Type **`yes`**. This destroys both the bucket and the (now-imported) instance.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `Instance ID does not exist` on `plan -generate-config-out` | Double-check the instance ID from Step 2 — it must be `running`, not still `pending`. |
| Step 4's plan shows changes to `aws_s3_bucket.app_logs` | Something else changed it — re-run `terraform plan` alone first to confirm the bucket is still drift-free before touching the import. |
| Generated `resource` block looks incomplete | Expected sometimes — `-generate-config-out` is a strong starting point, not guaranteed perfect; fill in any gaps by hand. |
| `terraform plan` shows changes instead of `No changes` after Step 5 | The generated code doesn't exactly match the real instance yet — review the diff and adjust the resource block before applying. |
| `UnauthorizedOperation` running the instance | Confirm your IAM user still has `AdministratorAccess`. |
