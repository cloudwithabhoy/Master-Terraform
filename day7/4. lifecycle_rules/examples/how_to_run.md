# How to Run This Example

**Goal:** Apply all three `lifecycle` rules for real, and observe exactly what each one changes
about Terraform's behavior — not just read about it.

> Cost: a VPC, a security group, and two small S3 buckets — all free. Expect ~$0.

---

## Step 0 — Move into this folder and apply everything

```bash
cd "day7/4. lifecycle_rules/examples"
terraform init
terraform apply
```
Type **`yes`**. This creates all four resources at once: `aws_s3_bucket.critical`
(`prevent_destroy`), `aws_s3_bucket.ignoring_tags` (`ignore_changes`), and `aws_vpc.main` +
`aws_security_group.web` (`create_before_destroy`).

---

## Experiment 1 — `create_before_destroy`

**What we're proving:** replacing the security group creates the new one *before* destroying the
old one, instead of the default destroy-then-create order.

Open `main.tf` and change the security group's `name` — this is a `ForceNew` argument, so changing
it forces a replacement:
```hcl
resource "aws_security_group" "web" {
  name   = "lifecycle-demo-sg-renamed-${random_id.suffix.hex}"   # <- changed
  vpc_id = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }
}
```

```bash
terraform apply
```
Type **`yes`**, and watch the output order closely:
```
aws_security_group.web: Creating...
aws_security_group.web: Creation complete after 2s [id=sg-0abc...]
aws_security_group.web (deposed object ...): Destroying...
aws_security_group.web (deposed object ...): Destruction complete after 1s
```
**Creating happens first, destroying happens second** — the opposite of the default order. If you
temporarily remove the `create_before_destroy` line and repeat this same rename, you'll see
`Destroying...` happen before `Creating...` instead — that's the default behavior this rule
overrides.

**Want to see it again?** Rename the security group a second time (any different string works —
e.g. append `-v2`) and run `terraform apply` again. You'll see the exact same pattern repeat:
`Creating...` for the new SG completes first, then the old one shows up as a `deposed object`
being destroyed second. This is fully repeatable — `create_before_destroy` isn't a one-time
behavior, it applies to *every* future replacement of this resource.

Change the `name` back to its original value (or just leave the renamed version — either is fine)
before moving on.

---

## Experiment 2 — `prevent_destroy`

**What we're proving:** Terraform hard-refuses to destroy a protected resource, even via a full
`terraform destroy` — and that the *only* way past it is editing the code.

```bash
terraform destroy
```
Type **`yes`**. Expect a **hard error**, something like:
```
Error: Instance cannot be destroyed

  on main.tf line 6:
   6: resource "aws_s3_bucket" "critical" {

Resource aws_s3_bucket.critical has lifecycle.prevent_destroy set, which prevents the destroy
```

Notice: **nothing was destroyed** — not just this bucket, but nothing else in this run either, per
the earlier lesson on how `prevent_destroy` blocks the whole operation, not just this one resource.

Now remove the protection, deliberately:
```hcl
resource "aws_s3_bucket" "critical" {
  bucket = "lifecycle-demo-critical-${random_id.suffix.hex}"

  # lifecycle {
  #   prevent_destroy = true
  # }
}
```

```bash
terraform apply
```
Type **`yes`** — this applies just the code change (removing the lifecycle block), with no actual
resource changes (`0 to add, 0 to change, 0 to destroy`).

```bash
terraform destroy
```
This time it will actually destroy `aws_s3_bucket.critical` along with everything else — hold off
on typing `yes` if you want to keep testing Experiment 3 first.

---

## Experiment 3 — `ignore_changes`

**What we're proving:** a manual tag change outside Terraform doesn't show up as drift at all.

Manually tag the bucket, simulating a teammate clicking around the console:
```bash
aws s3api put-bucket-tagging --bucket "$(terraform output -raw ignoring_tags_bucket_name)" \
  --tagging 'TagSet=[{Key=ManagedBy,Value=terraform},{Key=AddedManually,Value=true}]'
```

```bash
terraform plan
```
Expect **`No changes.`** — even though the real bucket now has an `AddedManually` tag your code
never mentions, `ignore_changes = [tags]` tells Terraform not to compare `tags` against reality at
all.

**See the contrast for yourself:** comment out the `ignore_changes = [tags]` line, then run
`terraform plan` again — now it *will* show a change, proposing to remove `AddedManually` and
bring the bucket back in line with your code. Put the `ignore_changes` line back afterward.

---

## Step 4 — Destroy everything

```bash
terraform destroy
```
Type **`yes`**. (If you skipped ahead and still have `prevent_destroy` active on the critical
bucket, go back to Experiment 2 and remove it first — this will otherwise fail on purpose.)

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `Instance cannot be destroyed` on `terraform destroy` | Expected in Experiment 2 — that's the lesson. Remove the `prevent_destroy` block, `apply`, then `destroy` again. |
| Experiment 1's apply doesn't show a clear create/destroy order | Make sure you actually changed the `name` argument — a no-op edit won't force a replacement. |
| Experiment 3's `plan` shows a change instead of `No changes` | Confirm `ignore_changes = [tags]` is still present (not commented out) and you tagged the correct bucket name. |
| `AccessDenied` on `put-bucket-tagging` | Confirm your IAM user still has `AdministratorAccess`. |
