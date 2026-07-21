# Day 8, Topic 1 — State Management (Remote Backends & Locking)

**Goal:** Move state off your laptop and into a shared, locked S3 backend — the setup any real
team needs so two people never corrupt the same state file by applying at once.

**Prerequisites:** [Day 7](../../day7/4.%20lifecycle_rules/lifecycle_rules.md) complete.

> For what S3 itself is, see Day 3's [`aws_s3.md`](../../day3/aws_s3.md) — this topic only adds
> what's specific to using S3 *as a Terraform backend*.

---

## 1. Recap: local state's problems

Every lab so far has used **local state** — a `terraform.tfstate` file sitting in the lab folder
(Day 3 Topic 2, §7). That's fine solo, but breaks down the moment more than one person touches
the same infrastructure:
- **No sharing** — your teammate's `plan` doesn't know what you already applied; they'd only have
  their own (nonexistent) local state.
- **No locking** — two people running `apply` at the same moment can corrupt the state file or
  create duplicate/conflicting resources.
- **No durability** — a local file lives on one laptop; delete it (or lose the laptop) and
  Terraform forgets every resource exists (Day 3 Topic 2, §7's warning, now solved).

---

## 2. The `backend "s3"` block

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "networking/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

- **`bucket`** — where the state file lives.
- **`key`** — the state file's "path" inside the bucket — different configs (or environments) use
  different keys, so they never share one state file.
- **`dynamodb_table`** — the lock table (see §3).
- **`encrypt`** — encrypts the state file at rest (state can contain sensitive values, Day 3
  Topic 2 §7).

---

## 3. Locking, precisely

When you run `plan`/`apply`, Terraform writes a lock item to the DynamoDB table (primary key
`LockID`) *before* touching the state file, and removes it when done. A second `apply` started
while a lock exists fails immediately with `Error acquiring the state lock` instead of racing the
first one — this is the whole reason the DynamoDB table exists alongside the S3 bucket: its
strong read-after-write consistency and conditional-write support make it a reliable choice for
this kind of lock, unlike trying to build the same guarantee out of another S3 object.

---

## 4. The bootstrap problem

The S3 bucket and DynamoDB table that *become* the backend can't themselves be created using that
backend — it doesn't exist yet. The standard pattern: a small, separate **bootstrap** config, using
ordinary local state, that creates just the bucket + table, run **once**, before any other config
adopts them as its backend — typically its own tiny `bootstrap/` subfolder, applied and then left
alone.

---

## 5. Migrating existing state to a new backend

```bash
terraform init -migrate-state
```

Run after adding (or changing) a `backend` block in a config that already has local (or a
different remote) state — Terraform detects the mismatch, asks to confirm, and copies the state
into the new backend. Nothing about your resources changes; only *where Terraform's record of
them lives* changes.

---

## 6. Reading another config's outputs: `terraform_remote_state`

```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.networking.outputs.public_subnet_id
  # ...
}
```

Lets one Terraform config (e.g. a "compute" config) read another's (e.g. a "networking" config's)
outputs, without them being the same state or even the same repo — the mechanism that makes
splitting infrastructure into independently-deployed pieces (Day 5 Topic 1's `environments/`
preview) actually work.

---

## 7. A first look at `terraform state` commands

- **`terraform state list`** — you've used this since Day 3.
- **`terraform state mv`** — rename a resource address in state without destroying/recreating it
  (e.g. after renaming a resource's local name in code).
- **`terraform state rm`** — remove a resource from state **without** destroying it in AWS (the
  opposite mistake from Day 3's "never delete `.tfstate` by hand" warning — this is the *safe*,
  deliberate version of that).

Bringing a resource *into* state that Terraform didn't create is `terraform import` — its own
full topic, Topic 3 of this same day.

---

## Small illustrative snippet

See [`examples/backend_and_remote_state.tf`](./examples/backend_and_remote_state.tf) for the
`backend "s3"` block and a `terraform_remote_state` read side by side (not directly applyable —
it references a bucket/table name you'd need to create for real first, via the bootstrap pattern
in §4).

---

## Checklist
- [ ] I can explain what problem remote state + locking solves that local state can't
- [ ] I can explain the "bootstrap problem" and why it needs a separate, local-state config
- [ ] I can explain what `terraform_remote_state` is for
- [ ] I know `state mv`/`state rm` change Terraform's bookkeeping, not real AWS resources

Next: **[Topic 2 — Modules](../2.%20modules/modules.md)**.
