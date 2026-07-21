# How to Run This Example

**Goal:** Create a real S3 bucket from code, manually change it outside Terraform (simulating a
teammate clicking around the AWS Console), then use drift detection to inspect — and resolve —
the difference.

> Cost: one small S3 bucket — free. Expect ~$0.

---

## Step 0 — Move into this folder

```bash
cd "day8/4. drift_detection/examples"
```

---

## Step 1 — Create the resource from code

```bash
terraform init
terraform apply
```

Type **`yes`**. This creates one S3 bucket, tagged `ManagedBy = terraform` — entirely from
`main.tf`, nothing manual yet.

```bash
terraform output bucket_name
```

Note the exact bucket name printed — you'll need it in Step 2.

---

## Step 2 — Manually change it, outside Terraform

Simulate a teammate editing the bucket by hand. Pick **either** option below — both produce the
exact same real-world result, so only do one:

**Option A — Actually click through the AWS Console:**
1. Sign in to the [AWS Console](https://console.aws.amazon.com/) and open the **S3** service.
2. Click the bucket name shown by `terraform output bucket_name` (Step 1).
3. Open the **Properties** tab, scroll down to **Tags**, and click **Edit**.
4. You should already see one tag: `ManagedBy = terraform`. Click **Add tag**.
5. Enter Key = `AddedManually`, Value = `true`.
6. Click **Save changes**.

**Option B — The CLI equivalent** (faster, same effect, no browser needed):
```bash
aws s3api put-bucket-tagging --bucket "$(terraform output -raw bucket_name)" \
  --tagging 'TagSet=[{Key=ManagedBy,Value=terraform},{Key=AddedManually,Value=true}]'
```

Either way, the bucket now has an `AddedManually` tag that `main.tf` never mentions. As far as AWS
is concerned, this already happened — Terraform just doesn't know about it yet.

---

## Step 3 — Detect the drift, without touching anything

```bash
terraform plan -refresh-only
```

Expect output showing `AddedManually = "true"` appearing as a change — but notice the plan
proposes **no action**. This is purely observational: "here's what's different in reality; you
decide what to do."

Compare it against an ordinary plan:

```bash
terraform plan
```

An ordinary `plan` **does** propose an action here — it would remove the `AddedManually` tag to
bring the bucket back in line with `main.tf`. That's the core distinction: `-refresh-only`
inspects, an ordinary `plan` proposes fixing.

---

## Step 4 — Resolve the drift, one of two ways

**Option A — Accept the manual change** (the tag was actually fine/intentional):
```bash
terraform apply -refresh-only
```
This updates **state only** — Terraform stops flagging the tag as drift. It does **not** update
`main.tf`, so if you want to keep this permanently, add the tag to `main.tf` by hand too.

**Option B — Revert the manual change** (it was a mistake, code is the source of truth):
```bash
terraform apply
```
This is an ordinary apply — it removes the `AddedManually` tag from the real bucket, bringing AWS
back in line with `main.tf`.

Only do one of these — they're opposites.

---

## Step 5 — Destroy

```bash
terraform destroy
```
Type **`yes`**.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `AccessDenied` on `put-bucket-tagging` | Confirm your IAM user still has `AdministratorAccess`. |
| Step 3's `-refresh-only` plan shows no drift | Confirm Step 2's command actually ran against the right bucket name (`terraform output -raw bucket_name`). |
| Step 4 doesn't seem to change anything | Make sure you only ran ONE of Option A/B, and re-run `terraform plan -refresh-only` afterward to confirm the drift is gone. |
