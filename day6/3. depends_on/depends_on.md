# Day 6, Topic 3 — `depends_on`, in Depth

**Goal:** Go beyond the one-line mention back on Day 3 — understand when Terraform's automatic
dependency graph is enough, when it isn't, and how to force ordering correctly (and as rarely as
possible) with `depends_on`.

**Prerequisites:** [Topic 2 — `count`](../2.%20count/count.md) read first.

---

## 1. Recap: implicit dependencies (the 95% case)

Whenever one resource's argument references another resource's attribute —
`subnet_id = aws_subnet.public["us-east-1a"].id` — Terraform sees the reference and creates an
edge in its **dependency graph** automatically. This is the **implicit dependency** from Day 3
Topic 2, and it's how almost every relationship in this course's labs so far has been expressed.
Prefer this whenever possible: it's self-documenting (the reference IS the reason), and it stays
correct automatically if the code changes.

---

## 2. When implicit dependencies aren't possible

Sometimes two resources are genuinely related, but nothing in one resource's *arguments*
references the other's *attributes* — so Terraform has no reference to build a graph edge from,
and (without help) might create them in either order, or in parallel.

Classic real example: an **IAM policy that grants access based on a naming convention**, not a
direct ARN reference:

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data"
}

# This role's policy doesn't reference aws_s3_bucket.data ANYWHERE — it's
# built from a hardcoded convention string, so Terraform can't infer the
# bucket must exist first, even though logically it must.
resource "aws_iam_role_policy" "access" {
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:GetObject"
      Resource = "arn:aws:s3:::my-app-data/*" # <- a STRING, not a reference
    }]
  })

  depends_on = [aws_s3_bucket.data]
}
```

Without `depends_on`, this *usually* still works (both resources might get created around the
same time regardless), but it's not **guaranteed**, and a `destroy` could tear down the bucket
before removing the role's dependency on it. `depends_on` makes the ordering explicit and correct.

That's the whole pattern — the same `depends_on = [...]` line works on any resource block.

---

## 3. The rule of thumb

1. **Can you reference an attribute instead?** Do that — it's an implicit dependency, always
   preferred.
2. **Genuinely no attribute to reference, but a real ordering requirement exists?** Use
   `depends_on`, scoped as narrowly as possible (prefer one resource over a whole module).
3. **Reaching for `depends_on` a lot** is often a sign the configuration's resources are more
   tangled than they should be — a good moment to reconsider whether they belong in separate
   modules with a real interface between them (Day 9).

---

## Small illustrative snippet

See [`examples/depends_on_demo.tf`](./examples/depends_on_demo.tf) — a `null_resource` "all
buckets ready" check that depends on every bucket from a `for_each`. This example is self-contained
and safe to `apply`/`destroy` on its own.

> **Good to know, not needed today:** `depends_on = [...]` also works on a whole `module` block
> (waits for every resource inside it) and on a `data` source (delays reading it until after a
> resource is created). Same idea, same syntax — you'll meet these forms naturally once you reach
> modules (Day 9).

---

## Checklist
- [ ] I can explain why some relationships can't produce an implicit dependency
- [ ] I can write a `depends_on` on a resource
- [ ] I know reaching for `depends_on` often should prompt "should this be two modules instead?"

Next: **Day 7**.
