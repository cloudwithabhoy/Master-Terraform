# Day 7, Topic 2 — Conditional Expressions

**Goal:** Learn Terraform's `condition ? true_val : false_val` syntax — how to make a single
value (an instance size, a tag, a setting) depend on something else, like which environment
you're deploying to.

**Prerequisites:** `count` (Day 6, Topic 2) helps, but isn't required for this topic on its own.

---

## 1. The syntax

```hcl
condition ? value_if_true : value_if_false
```

Read it in plain English: *"If `condition` is true, use the first value; otherwise, use the
second."* It's the same idea as an `if/else`, just written as one expression instead of a block —
because Terraform is declarative, there's no `if` statement, only expressions that resolve to a
value.

Both `value_if_true` and `value_if_false` must be **compatible types** — you can't return a
string from one branch and a number from the other; Terraform needs to know the result's type
regardless of which branch runs.

---

## 2. A real example: sizing an instance by environment

```hcl
variable "environment" {
  type    = string
  default = "prod"
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  tags = {
    Name = "web"
  }
}
```

- **`var.environment == "prod"`** — the condition. This evaluates to `true` or `false`.
- **`"t3.large"`** — used if the condition is `true` (we're in `prod`).
- **`"t3.micro"`** — used if the condition is `false` (any other environment).

With the default (`environment = "prod"`), this resolves to `"t3.large"`. Run
`terraform apply -var="environment=dev"` instead, and it resolves to `"t3.micro"` — a **different**
value than the default, which is exactly why `instance_type` is a `ForceNew` attribute here: AWS
can't resize a running instance in place, so Terraform destroys and recreates it with the new size.

---

## 3. A second conditional value, on the same resource

Nothing limits you to one conditional expression per resource — here, a `tags` value is decided
the same way, completely independently of `instance_type`:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  tags = {
    Name   = "web"
    Backup = var.environment == "prod" ? "Enabled" : "Disabled"
  }
}
```

`Backup` becomes `"Enabled"` in `prod`, `"Disabled"` everywhere else — modeling a real policy
("only back up production") as data instead of a separate resource block or manual toggle.

---

## 4. The other common use: toggling a whole resource on/off

The pattern above picks between two **values**. The other major use of a conditional expression
is picking between **1 and 0** for `count`, which toggles whether an entire resource exists at
all:

```hcl
resource "aws_db_instance" "database" {
  count = var.environment == "prod" ? 1 : 0
  # ...
}
```

When `count` evaluates to `0`, Terraform creates **zero** instances of this resource — it's
skipped entirely, not created-then-ignored. Referencing a resource created this way needs a guard,
since `aws_db_instance.database` isn't a single object once `count` is set — you must address a
specific index, guarded by the same condition:

```hcl
output "database_endpoint" {
  value = var.environment == "prod" ? aws_db_instance.database[0].endpoint : null
}
```

Without the guard, this output would fail whenever `environment != "prod"`, since
`aws_db_instance.database[0]` wouldn't exist to reference.

---

## 5. Common mistakes

- **Mismatched types across branches** — e.g. `condition ? "yes" : 0` — Terraform needs one
  consistent type for the result, regardless of which branch actually runs.
- **Deeply nested ternaries** (`a ? b : c ? d : e`) — technically valid, but hard to read past one
  level. A `local` with a clearer name, or a `for` expression / lookup table, is usually more
  maintainable.
- **Forgetting the `[0]` guard** (§4) when referencing a conditionally-created resource — the #1
  runtime error this pattern produces for beginners.

---

## Small illustrative snippet

See [`examples/main.tf`](./examples/main.tf) for the conditional-value pattern, applyable: an EC2
instance's `instance_type` and `Backup` tag both driven by `var.environment`.

---

## Checklist
- [ ] I can write `condition ? a : b` and explain why both branches should share a type
- [ ] I can use a conditional expression to set more than one attribute on the same resource
- [ ] I can explain why `count = condition ? 1 : 0` is how you make a resource optional, and why
      referencing it needs a guard

Next: **Day 8**.
