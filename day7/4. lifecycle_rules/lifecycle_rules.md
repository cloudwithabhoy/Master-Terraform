# Day 8, Topic 3 — Lifecycle Rules

**Goal:** Learn the `lifecycle {}` meta-argument — `create_before_destroy`,
`prevent_destroy`, and `ignore_changes` — the tools for controlling exactly how and when
Terraform is allowed to replace or destroy a resource.

**Prerequisites:** [Topic 2 — Terraform Functions](../3.%20terraform_functions/terraform_functions.md)
read first.

---

## 1. `lifecycle` is a meta-argument, not a resource type

Every resource can have a `lifecycle {}` block — it's not tied to any particular resource type,
it changes **how Terraform manages** that resource, regardless of what kind it is.

```hcl
resource "aws_security_group" "web" {
  # ... normal arguments ...

  lifecycle {
    create_before_destroy = true
  }
}
```

---

## 2. `create_before_destroy`

By default, when a change forces replacement (Day 3's `-/+` plan symbol), Terraform **destroys
the old resource, then creates the new one**. For some resources, that gap matters — e.g. a
security group still referenced by a running instance can't be deleted at all until the instance
stops referencing it, causing a `DependencyViolation` error.

`create_before_destroy = true` flips the order: **create the replacement first**, re-point
anything that referenced the old one, *then* destroy the old one. This is why the shared lab
today applies it to a security group specifically.

---

## 3. `prevent_destroy`

```hcl
resource "aws_s3_bucket" "critical" {
  bucket = "my-critical-data"

  lifecycle {
    prevent_destroy = true
  }
}
```

Terraform **refuses** to destroy this resource — via `terraform destroy`, or a plan that would
replace it — with a hard error, until the `prevent_destroy` line is removed from the code. This
is a deliberate speed bump for genuinely irreplaceable resources (a production database, a bucket
holding customer data) — protection against a mistyped `destroy` or an unreviewed `plan` doing
something catastrophic.

> **Today's lab deliberately demonstrates this the hard way**: you'll try to destroy a
> `prevent_destroy`-protected bucket, watch it fail, then remove the block and destroy it for
> real — so the failure mode is something you've actually seen, not just read about.

---

## 4. `ignore_changes`

```hcl
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux.id
  # ...

  lifecycle {
    ignore_changes = [ami]
  }
}
```

Tells Terraform to stop treating changes to specific argument(s) as drift needing a fix. Without
this, every `plan` after AWS publishes a newer AMI would show your `aws_instance` as needing
replacement — even though nothing about *your intent* changed, just what "latest" resolves to
today. `ignore_changes = [ami]` says "I picked an AMI when I created this; don't replace it just
because a newer one now exists."

Can also take `all` (ignore every future change to every argument — rare, usually a sign of a
deeper problem) or a specific list of argument names (the common, precise usage).

---

## 5. Combining lifecycle arguments

```hcl
resource "aws_instance" "web" {
  # ...
  lifecycle {
    create_before_destroy = true
    ignore_changes         = [ami, tags]
  }
}
```

All three arguments can be combined on the same resource when each solves a genuinely separate
problem for it.

---

## 6. When to reach for each

| Situation | Argument |
|-----------|----------|
| Replacing this resource breaks something that references it, unless the new one exists first | `create_before_destroy` |
| This resource must never be destroyed by accident | `prevent_destroy` |
| An upstream value (like "latest AMI") shouldn't force replacement every time it changes | `ignore_changes` |

---

## Small illustrative snippet

See [`examples/main.tf`](examples/main.tf) for all three, on resources you can actually
apply/destroy to see the behavior, and [`examples/how_to_run.md`](examples/how_to_run.md) for a
full step-by-step walkthrough testing each rule individually.

---

## Checklist
- [ ] I can explain what `create_before_destroy` changes about a replacement
- [ ] I can explain why `prevent_destroy` produces a hard error, and how to remove it deliberately
- [ ] I can explain a real reason to use `ignore_changes` (not just "to make errors go away")

Next: **Day 8**.
