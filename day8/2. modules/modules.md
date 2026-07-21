# Day 8, Topic 2 — Modules

**Goal:** Package a group of resources into a reusable module with a real input/output "API," and
call it more than once with different inputs — turning a VPC and Day 6's `for_each`-based EC2
pattern into something callable instead of copy-pasted.

**Prerequisites:** [Topic 1 — State Management](../1.%20state_management/state_management.md)
read first.

---

## 1. What a module actually is

Every lab so far has technically already been a module — Terraform calls the folder you run
`init`/`apply` in the **root module**. A module is just **a folder containing `.tf` files**;
"authoring a module" means writing one specifically to be *called* by other configs, with
`variables.tf` as its inputs and `outputs.tf` as its outputs — nothing new syntactically, just a
new way to use what you already know.

---

## 2. Anatomy of a callable module

```
modules/vpc/
├── main.tf       ← the resources (a VPC: subnets, IGW, route table, SG)
├── variables.tf  ← inputs: cidr, public_subnets, private_subnets, name_prefix, tags
└── outputs.tf    ← outputs: vpc_id, public_subnet_ids, private_subnet_ids
```

Nothing here differs from any lab you've already built — `variables.tf`/`outputs.tf` are the
module's **public interface**; anything not exposed as an output is private to the module,
invisible to whoever calls it.

---

## 3. The `module` block

```hcl
module "vpc" {
  source = "../modules/vpc"

  name_prefix     = "myapp-dev"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = { "us-east-1a" = "10.0.0.0/24" }
  private_subnets = { "us-east-1a" = "10.0.10.0/24" }
}
```

- **`source`** — where the module's code lives. A relative path (as above) is a **local module**;
  it can also be a Terraform Registry address (`terraform-aws-modules/vpc/aws`) or a Git URL.
- Every other argument matches one of the module's declared `variable`s.
- Reference the module's outputs elsewhere as `module.vpc.vpc_id`,
  `module.vpc.public_subnet_ids`, etc. — exactly like referencing a resource's attributes.

---

## 4. Calling the same module more than once

```hcl
module "compute_web" {
  source          = "../modules/compute"
  subnet_id       = module.vpc.public_subnet_ids["us-east-1a"]
  instance_count  = 2
}

module "compute_worker" {
  source          = "../modules/compute"
  subnet_id       = module.vpc.public_subnet_ids["us-east-1a"]
  instance_count  = 1
}
```

Two `module` blocks, same `source`, different inputs — this is the entire point: the module's
*code* is written once; every environment/tier/purpose is just a different call with different
variable values, exactly what Day 5 Topic 1 previewed as "Stage 2" of a growing project.

---

## 5. Module versioning (registry modules)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # same constraint syntax as Day 4 Topic 1, applied to a module

  # ...
}
```

Registry (and Git) module sources support a `version` constraint using the exact same operators
Day 4 Topic 1 covered for providers — pin modules the same way, for the same reason (predictable
upgrades, no surprise breaking changes).

---

## 6. Common mistakes

- **Putting provider configuration inside a module** — a module should generally **not** contain
  `provider` blocks; the calling ("root") config configures providers, and the module just uses
  whatever's passed down. Keeps a module portable across different accounts/regions.
- **Not exposing an output you'll need later** — if the calling config needs an attribute, it
  MUST be in the module's `outputs.tf`; there's no way to "reach into" a module's private
  resources from outside.
- **One module trying to do too much** — if a module's `variables.tf` is enormous and covers
  unrelated concerns, that's usually a sign it should be two modules, not one (the same signal
  Day 6 Topic 3 flagged for overused `depends_on`).

---

## Small illustrative snippet

See [`examples/calling_a_module.tf`](./examples/calling_a_module.tf) for the two-call pattern
from §4 — reference material to read alongside a real `modules/vpc` + `modules/compute` pair you
build yourself, following §2's anatomy.

---

## Checklist
- [ ] I can explain what makes a folder of `.tf` files "a module" vs. just "a root config"
- [ ] I can write a `module` block with a local `source` and reference its outputs
- [ ] I can explain why calling one module twice beats copy-pasting its resources twice
- [ ] I can explain why provider blocks don't belong inside a module

Next: **[Topic 3 — `terraform import`](../3.%20terraform_import/terraform_import.md)**.
