# Day 8, Topic 3 — `terraform import`

**Goal:** Bring a resource that already exists in AWS (created by hand, by another tool, or by a
teammate outside Terraform) under Terraform's management, without destroying and recreating it.

**Prerequisites:** Topics 1-2 of this day complete.

---

## 1. Why this is needed at all

Every resource this course has created so far was born under Terraform's management, from
`apply` #1. In the real world, that's often not true — and it's rarely a *whole empty account*
either: your team already has a real, working Terraform codebase (some resources, already
applied), and *one more* resource turns up that someone created by hand, outside it. Your job is
to bring just that one resource under management, *without* touching anything else you already
have, and without deleting and recreating it (which would mean downtime, a new ID, and possibly
lost data).

---

## 2. Create something to import — simulating a hand-launched EC2 instance

Before you can practice importing, you need two things: a real, already-managed resource (so this
feels like a real codebase, not an empty folder), and a second real resource Terraform doesn't
know about yet.

[`examples/main.tf`](examples/main.tf) is the first part — an ordinary, already-applied S3 bucket,
standing in for "everything your team already has." Apply it first.

For the second part, launch an EC2 instance directly — via the AWS Console, or the CLI
equivalent — exactly like a teammate might have done by hand:

```bash
AMI_ID=$(aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query "reverse(sort_by(Images, &CreationDate))[0].ImageId" --output text)

aws ec2 run-instances --image-id "$AMI_ID" --instance-type t2.micro --count 1 \
  --query "Instances[0].InstanceId" --output text
```

Note the exact instance ID it prints (`i-0abcdef1234567890`) — that's the real-world ID you'll
import in a moment. As far as Terraform is concerned right now, this instance doesn't exist (no
`.tf` code, no state entry) — even though the bucket right next to it, from `main.tf`, is fully
managed. Exactly the mixed reality `terraform import` exists for.

See [`examples/how_to_run.md`](examples/how_to_run.md) for the full step-by-step version of this,
including the actual AWS Console click-path if you'd rather do it by hand for real.

---

## 3. The imperative CLI command

```bash
terraform import aws_instance.legacy i-0abcdef1234567890
```

- **`aws_instance.legacy`** — the resource address you want this real instance to be tracked as.
- **`i-0abcdef1234567890`** — the resource's real-world ID (varies by resource type — a bucket
  name, an instance ID, an ARN, etc. — check the provider docs for each type's expected import ID
  format).

**Critically:** `terraform import` only populates **state** — it does **not** write any `.tf`
code for you. You must already have (or immediately write) a matching `resource` block, or the
very next `plan` will show Terraform wanting to *destroy* the now-tracked resource (because your
code says it shouldn't exist).

---

## 4. The modern, declarative alternative: `import` blocks

```hcl
import {
  to = aws_instance.legacy
  id = "i-0abcdef1234567890" # the exact instance ID from §2
}

resource "aws_instance" "legacy" {
  # ... filled in via -generate-config-out, §5 — an EC2 instance has far too
  # many possible arguments to safely hand-write from memory
}
```

An `import` block does the same thing as the CLI command, but lives in your `.tf` code — visible
in review, repeatable, and plannable (`terraform plan` shows an import as part of the plan output
before you `apply` it). Introduced in Terraform 1.5, this is now the recommended approach over the
imperative CLI command for anything beyond a one-off, throwaway import.

---

## 5. Generating the matching resource block for you

Writing the `resource` block by hand to *exactly* match every argument of a real, already-existing
resource is tedious and error-prone. Since Terraform 1.5:

```bash
terraform plan -generate-config-out="generated.tf"
```

Run this after adding an `import` block (with no matching `resource` block yet) — Terraform reads
the real resource's current configuration and writes a best-effort `resource` block for you into
`generated.tf`. **Always review it carefully** — generated code is a strong starting point, not
guaranteed to be perfect (some attributes may need manual cleanup, especially ones Terraform can't
introspect fully).

Check the plan summary too: your existing `aws_s3_bucket` from §2 should show **no changes at
all** in the same plan — proof that adding an import doesn't touch infrastructure you already had.

---

## 6. The workflow, end to end

1. Identify the resource's real-world ID (§2 — console, CLI, or the other tool that created it).
2. Write an `import` block (§4).
3. Run `terraform plan -generate-config-out="generated.tf"` (§5) if you don't already have a
   matching `resource` block.
4. Review the generated code; move/clean it into your real `.tf` files.
5. Run `terraform plan` — expect **`No changes`** if the generated code exactly matches reality.
   Any diff shown here is a mismatch between your code and the real resource to resolve *before*
   applying anything.
6. `terraform apply` to finalize the import (the `import` block itself only needs to exist for
   one apply — remove it afterward; it's a one-time action, not an ongoing configuration).

---

## 7. Common mistakes

- **Forgetting the matching `resource` block** — the #1 error; import alone just updates state,
  your code must already describe the resource or the next plan tries to destroy it.
- **Not reviewing generated code** — `-generate-config-out` is a strong starting point, never a
  guaranteed-correct final answer.
- **Leaving the `import` block in place indefinitely** — it's a one-time migration instruction,
  not meant to be a permanent part of your configuration.

---

## Small illustrative snippet

See [`examples/main.tf`](examples/main.tf) for the pre-existing, already-managed resource this
import gets added alongside, [`examples/import.tf`](examples/import.tf) for
the `import` block from §4, and [`examples/how_to_run.md`](examples/how_to_run.md) for the
complete step-by-step walkthrough, including the actual AWS Console click-path for launching the
instance by hand.

---

## Checklist
- [ ] I can explain why `terraform import` alone isn't enough — what else is required
- [ ] I can write an `import` block and know it's a one-time, removable instruction
- [ ] I know `-generate-config-out` exists and that its output must be reviewed, not trusted blindly

Next: **[Topic 4 — Drift Detection](../4.%20drift_detection/drift_detection.md)**.
