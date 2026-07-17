# Day 6, Topic 2 — `count`

**Goal:** Learn Terraform's other repetition mechanism — `count` — in depth: `count.index`,
splat expressions, and precisely when it's the right tool versus Topic 1's `for_each`.

**Prerequisites:** [Topic 1 — `for_each`](../1.%20for_each/for_each.md) read first.

---

## 1. The basic form

```hcl
resource "aws_s3_bucket" "fleet" {
  count = 3

  bucket = "myapp-fleet-${count.index}-${random_id.suffix.hex}"
  tags   = { Name = "fleet-${count.index}" }
}
```

Read it in plain English: *"Create 3 copies of this bucket."*

- **`count = 3`** — creates three instances of this resource.
- **`count.index`** — `0`, `1`, `2` inside each instance — the only per-instance differentiator
  `count` gives you.
- The **resource address** becomes `aws_s3_bucket.fleet[0]`, `aws_s3_bucket.fleet[1]`,
  `aws_s3_bucket.fleet[2]` — positional (a plain number), unlike `for_each`'s string keys
  (`["logs"]`).

---

## 2. `count` driven by a variable

```hcl
variable "fleet_size" {
  type    = number
  default = 2
}

resource "aws_s3_bucket" "fleet" {
  count  = var.fleet_size
  bucket = "myapp-fleet-${count.index}-${random_id.suffix.hex}"
}
```

This is the idiomatic pattern for "how many of this thing" — driving the count from a variable
instead of a hardcoded number, so a `.tfvars` file (Day 5 Topic 2) can control it per environment.

---

## 3. Referencing every instance: splat expressions

```hcl
output "fleet_bucket_names" {
  value = aws_s3_bucket.fleet[*].bucket
}
```

`aws_s3_bucket.fleet[*].bucket` (a **splat expression**) collects the `bucket` attribute from
**every** instance into a single list — the `count`-based equivalent of Topic 1's
`[for b in aws_s3_bucket.app : b.bucket]` `for` expression over a `for_each` map.

---

## 4. `count` vs. `for_each` — the decision, precisely

| | `count` | `for_each` |
|---|---|---|
| Input | A number | A map or a set of strings |
| Instance address | Positional: `[0]`, `[1]` | Keyed: `["logs"]`, `["dev"]` |
| Removing a middle item | **Shifts every later index** — Terraform sees this as "destroy N, recreate N+1 through the end with different arguments," even if their actual config didn't change | Only the removed key's instance is affected; every other instance is untouched |
| Best for | Identical resources where "how many" is the only variable (a fleet of near-identical buckets) | Resources that differ meaningfully by a stable key (buckets per purpose, subnets per AZ) |

[`examples/count_demo.tf`](./examples/count_demo.tf) and Topic 1's
[`examples/for_each_demo.tf`](../1.%20for_each/examples/for_each_demo.tf) demonstrate this side by
side on real EC2 instances — removing a middle item from the `for_each` map only affects that one
key, while doing the same to the `count`-based list reshuffles everything after it.

---

## 5. Common mistakes

- **Using `count` when instances actually differ by more than a number** — if instance `0` needs
  different config than instance `1` beyond just `count.index`-based naming, that's a sign
  `for_each` (with a map carrying the real differences) is the better fit.
- **Forgetting the `[*]` / `[0]` when referencing a `count` resource elsewhere** — `aws_s3_bucket.fleet`
  alone (no index) is not a single instance once `count` is set; you must address a specific
  index or use a splat expression.
- **Setting `count = 0` expecting "no instances, but still validate the block"** — this is
  actually the exact mechanism Day 7's conditional expressions topic formalizes for toggling a
  resource on/off entirely.

---

## Small illustrative snippet

See [`examples/count_demo.tf`](./examples/count_demo.tf) for the fleet + splat pattern, and a
demonstration of the "removing a middle item reshuffles everything after it" behavior from §4.

---

## Checklist
- [ ] I can write a `count`-based resource and reference `count.index`
- [ ] I can write a splat expression to collect one attribute from every instance
- [ ] I can explain, precisely, when `for_each` is safer than `count` for a changing list

Next: **[Topic 3 — `depends_on`](../3.%20depends_on/depends_on.md)**.
