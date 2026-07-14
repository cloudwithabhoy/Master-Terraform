# Day 3, Topic 1 — Variables, Locals & Outputs

**Goal:** Stop hardcoding values in your `.tf` files. Learn the three "flavors" of variable
Terraform has — input `variable`, computed `local`, and returned `output` — plus `data` sources,
in enough depth to use all four confidently.

**Prerequisites:** [Day 2 setup](../../Day%202-setup/setup-aws-terraform.md) complete — `aws
configure` works and the smoke-test lab printed your account ID.

> This topic is theory + small standalone snippets (see [`examples/`](./examples/)) — no AWS
> resources created here. Today's topic 2, [First Resource](../2.%20first_resource/first_resource.md),
> builds the mechanics of a real resource; today's [shared lab](../lab/lab.md) applies everything
> from both topics together.

---

## 1. The problem with hardcoding

A resource with its name, tags, and region typed directly into `main.tf` is fine for a one-off
experiment, but it breaks down fast:
- Want a `dev` and a `prod` copy? Copy-paste the whole file and edit strings by hand — error-prone.
- Want a teammate to run your code with *their* name in the `Owner` tag? They'd have to edit your
  `.tf` files, which is exactly the "not shareable" problem Day 1 warned about.

Terraform gives you four distinct tools for this, and beginners often blur them together:

| Kind | Direction | Purpose |
|------|-----------|---------|
| **Input `variable`** | goes **in** | Something supplied from outside your config (CLI, file, env, or a default) — makes your code *configurable*. |
| **`local`** | computed **inside** | A named expression derived from variables/resources/other locals — avoids repeating a calculation. |
| **`output`** | comes **out** | A value your config *returns* after apply (an ID, an ARN, a URL) — for humans, other configs, or scripts to read. |
| **`data` source** | reads **in**, read-only | A lookup of something that already exists — creates nothing. |

---

## 2. Input variables, in depth

```hcl
variable "environment" {
  description = "Which environment this is (dev, stage, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}
```

- **`type`** — Terraform checks the value matches (`string`, `number`, `bool`, `list(...)`,
  `map(...)`, `object({...})`, or `any`). Catches mistakes before `apply`. See
  [`examples/variable_types.tf`](./examples/variable_types.tf) for all of these side by side.
- **`default`** — used if nothing else is supplied. Omit it to make a variable **required**.
- **`validation`** — a condition that must hold, with a message shown if it doesn't. A variable
  can have **multiple** `validation` blocks; all must pass. Cheap insurance against typos becoming
  AWS errors five minutes later.
- **`sensitive`** — hides the value in `plan`/`apply` output and in `terraform output` unless
  asked for by name (`terraform output <name>`). Protects against accidental leaks in a terminal
  or CI log — it does **not** encrypt the value inside the state file, which is still sensitive as
  a whole (Day 3 Topic 2, state-file section).

You reference a variable anywhere in your config as `var.environment`.

### Where values come from (precedence, highest wins)
1. `-var="environment=stage"` on the command line
2. `-var-file="prod.tfvars"` on the command line
3. `*.auto.tfvars` files in the folder (loaded automatically, no flag needed)
4. `TF_VAR_environment` environment variable
5. The `default` in the variable block
6. Terraform **prompts you** interactively if nothing else supplies it

> Real secrets (passwords, tokens) belong in a `*.tfvars` file that is **gitignored** — never in
> a variable's `default`, which gets committed.

---

## 3. `locals` — values computed once, used everywhere

```hcl
locals {
  name_prefix = "${var.project_prefix}-${var.environment}"

  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    Owner       = var.owner_tag
  }
}
```

A `local` isn't an input like a variable — it's a **named expression**, computed from variables,
resources, or other locals, so you don't repeat the same calculation (or the same tag map) in ten
places. Reference it as `local.common_tags`. Change the shape of `common_tags` here once, and
every resource that references it picks up the change automatically. See
[`examples/locals_and_outputs.tf`](./examples/locals_and_outputs.tf).

---

## 4. `output`, in depth

```hcl
output "bucket_name" {
  description = "The generated name of the bucket."
  value       = aws_s3_bucket.example.bucket
}

output "alert_webhook_url" {
  description = "Where alerts would be sent (pretend secret, for teaching sensitive outputs)."
  value       = var.alert_webhook_url
  sensitive   = true
}
```

Outputs are how a config "returns" values — to you at the terminal, to a script, or (later, Day 9)
to another Terraform config via `terraform_remote_state`. `sensitive = true` on an output works
the same way as on a variable: hidden by default, visible if asked for by name.

**Without `sensitive = true`**, `terraform apply` would print:
```
Outputs:

alert_webhook_url = "https://example.com/replace-me"
```

**With it**, the same `apply` prints:
```
Outputs:

alert_webhook_url = <sensitive>
```

The real value isn't gone — `terraform output alert_webhook_url` (asking for it **by name**) still
prints it in plain text. `sensitive` only suppresses it from the *general* dump, guarding against
an accidental leak into your terminal scrollback or a CI log, not true access control.

---

## 5. `data` sources — reading, not creating

A **data source** looks up something that already exists and hands you its attributes — it
creates nothing and appears in plans with the `<=` symbol (see Day 3 Topic 2's plan-symbols
table).

```hcl
data "aws_caller_identity" "current" {}
```

This returns the AWS **account ID**, user/role ARN, and user ID of whoever is running Terraform
right now — useful for building account-specific ARNs without hardcoding a 12-digit number that
would break the moment someone else (or a different account) runs your code. See
[`examples/data_sources.tf`](./examples/data_sources.tf).

---

## Checklist
- [ ] I can explain the difference between a `variable`, a `local`, an `output`, and a `data`
      source in one sentence each
- [ ] I declared a variable with a `validation` block and understand why it fails before touching AWS
- [ ] I understand variable precedence (CLI `-var` beats a `.tfvars` file beats a `default`)
- [ ] I marked something `sensitive` and understand what it does (and doesn't) protect against

Next: **[First Resource](../2.%20first_resource/first_resource.md)**.
