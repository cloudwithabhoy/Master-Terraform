# Day 6, Topic 1 — `for_each`

**Goal:** Stop copy-pasting near-identical resource blocks. Learn `for_each` over a map, the
`each.key`/`each.value` objects, and when it beats `count` (Topic 2, right after this).

**Prerequisites:** [Day 5](../../day5/lab/lab.md) complete.

---

## 1. The problem `for_each` solves

Say you need one S3 bucket per purpose — `logs`, `backups`. Without `for_each`, that means a
separate, nearly-identical `resource` block per bucket, which is exactly the repetition this
course has warned about since Day 3.

---

## 2. `for_each` over a map — the one pattern to learn first

```hcl
variable "bucket_purposes" {
  type = map(string)
  default = {
    logs    = "log-retention"
    backups = "disaster-recovery"
  }
}

resource "aws_s3_bucket" "app" {
  for_each = var.bucket_purposes

  bucket = "myapp-${each.key}-${random_id.suffix.hex}"
  tags   = { Purpose = each.value }
}
```

Read it in plain English: *"For each entry in `bucket_purposes`, create one S3 bucket."*

- **`for_each = var.bucket_purposes`** — loop once per map entry.
- **`each.key`** — this entry's key (`"logs"`, then `"backups"`).
- **`each.value`** — this entry's value (`"log-retention"`, then `"disaster-recovery"`).
- The **resource address** becomes `aws_s3_bucket.app["logs"]` and `aws_s3_bucket.app["backups"]`
  — each instance individually addressable **by name**, unlike `count`'s numeric `[0]`/`[1]`
  (Topic 2 covers why that difference matters).

That's the whole pattern. Everything below is detail you'll need eventually, not today.

---

## 3. Referencing every instance at once

```hcl
output "bucket_names" {
  value = { for purpose, b in aws_s3_bucket.app : purpose => b.bucket }
}
```

`aws_s3_bucket.app` (with `for_each`) is a **map of objects**, one per key — a `for` expression
like this one turns it into a plain map/list for an output or another resource to consume.

---

## 4. Common mistakes

- **Using a `list` instead of a `map`** — `for_each` needs a map (or a set of strings), not a
  list, specifically so each instance has a **stable, non-positional** key. (`count` is the tool
  for plain lists — Topic 2.)
- **Computing the `for_each` value from something not known until apply** — Terraform needs to
  know the *keys* during `plan`, before anything is created; a `for_each` map built from an
  attribute of a not-yet-created resource will fail with "Invalid for_each argument."

---

## Small illustrative snippet

See [`examples/for_each_demo.tf`](./examples/for_each_demo.tf) — the exact map-based pattern
above, plus the `for` expression projection from §3.

> **Good to know, not needed today:** `for_each` also works over a `set(string)` (e.g.
> `["dev", "qa"]` converted with `toset(...)`) — there, `each.key` and `each.value` are just the
> same string, since a set has no separate key/value. You'll see this if you ever loop over a
> plain list of names instead of a map.

---

## Checklist
- [ ] I can write a `for_each` over a `map(string)` and reference `each.key`/`each.value`
- [ ] I can explain why `for_each` needs a map, not a list
- [ ] I can project a `for_each` resource's instances into a map with a `for` expression

Next: **[Topic 2 — `count`](../2.%20count/count.md)**.
