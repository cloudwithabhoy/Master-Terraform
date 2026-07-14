# Day 4, Topic 1 — Version Constraints

**Goal:** Understand why every lab in this course pins versions (`required_version`,
`required_providers`), what the constraint operators actually mean, and how the dependency lock
file keeps a team reproducible.

**Prerequisites:** [Day 3](../../day3/lab/lab.md) complete.

---

## 1. Why pin versions at all

Terraform and its providers both ship new versions constantly — bug fixes, new resources, and
occasionally **breaking changes**. Without a pin, the same `.tf` code could behave differently on
your laptop, your teammate's laptop, and CI, depending on whatever version each happened to
download that day. Version constraints turn "it works on my machine" into "it works, reproducibly,
everywhere" — the same guarantee Day 1 promised for infrastructure itself, now applied to the tool
that builds it.

---

## 2. `required_version` — pinning the Terraform CLI itself

```hcl
terraform {
  required_version = ">= 1.5"
}
```

If whoever runs `terraform init` has an older CLI than this, Terraform **refuses to run** with a
clear error, instead of silently misbehaving on syntax or features the old CLI doesn't understand.

---

## 3. `required_providers` — pinning each provider

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- **`source`** — `<namespace>/<name>`. `hashicorp/aws` is the official AWS provider; a third-party
  provider would use its publisher's namespace instead (e.g. `cloudflare/cloudflare`).
- **`version`** — the constraint. Every lab in this course uses `~> 5.0` for the AWS provider —
  meaning "any 5.x release, but never 6.0" (see the operators below for exactly why).

---

## 4. Constraint operators, precisely

| Operator | Meaning | Example | Allows |
|----------|---------|---------|--------|
| `=` (or nothing) | Exactly this version | `= 5.31.0` | Only `5.31.0` |
| `!=` | Any version except this one | `!= 5.20.0` | Everything but `5.20.0` |
| `>`, `>=`, `<`, `<=` | Ordinary numeric comparison | `>= 5.0` | `5.0` and anything newer |
| `~>` (pessimistic/"twiddle-wakka") | Allows the **rightmost** version component to increment, nothing higher | `~> 5.0` → allows `5.1`, `5.9`, `5.99`... but not `6.0`. `~> 5.1.2` → allows `5.1.3`, `5.1.99`... but not `5.2.0`. | The most common real-world constraint |

`~>` is what you'll use almost everywhere: it says "give me bug fixes and safe feature additions,
but never a version that might break my code." See
[`examples/version_operators.tf`](./examples/version_operators.tf) for every operator side by
side.

---

## 5. Semantic versioning — what the numbers mean

Providers (and Terraform itself) follow **semver**: `MAJOR.MINOR.PATCH`, e.g. `5.31.0`.

| Component | Increments when | Should break your code? |
|-----------|------------------|--------------------------|
| **MAJOR** | Breaking changes (removed/renamed resources or arguments) | Possibly — read the changelog before upgrading |
| **MINOR** | New features, backward compatible | No |
| **PATCH** | Bug fixes only, backward compatible | No |

This is *exactly* why `~> 5.0` is the right default: it tracks MINOR and PATCH updates
automatically (bug fixes, new resources) while refusing to silently jump to a MAJOR version that
could break your existing `.tf` code.

---

## 6. The dependency lock file

`terraform init` writes a `.terraform.lock.hcl` file recording the **exact** provider versions and
checksums it resolved, given your constraints. Rules:
- **Commit it to git** (unlike `.tfstate`) — it's what makes a second `init`, by you or a
  teammate, resolve to the identical provider version, not just "any version matching the
  constraint."
- It updates automatically only when you run `terraform init -upgrade` (deliberately re-resolving
  within your constraints) or when you widen a constraint that no longer matches the locked
  version.
- If teammates get "provider version doesn't match lock file" errors, that's the lock file doing
  its job — it caught an environment drift before it caused a subtler bug.

---

## 7. Upgrading deliberately

```bash
terraform init -upgrade    # re-resolve to the newest version matching your constraints
```

The safe upgrade loop: read the provider's changelog for the target version → widen/adjust the
constraint if needed → `terraform init -upgrade` → `terraform plan` (read it carefully — a
provider upgrade can occasionally show unexpected diffs even with no code changes, if the provider
changed a default) → commit the updated lock file.

---

## Checklist
- [ ] I can explain why `required_version`/`required_providers` exist in one sentence
- [ ] I can read `~> 5.0` and say exactly which versions it allows and excludes
- [ ] I know the difference between MAJOR/MINOR/PATCH and which ones are safe to auto-accept
- [ ] I know the lock file gets committed to git, unlike `.tfstate`

Next: **[Topic 2 — IAM as Code](../2.%20iam_as_code/iam_as_code.md)**.
