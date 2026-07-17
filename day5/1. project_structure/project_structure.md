# Day 5, Topic 1 — AWS Terraform Project Structure Best Practices

**Goal:** Learn how to lay out a growing Terraform project so a new teammate (or you, in six
months) can find anything in seconds — file-per-concern conventions, naming, tagging, and where
environments and modules eventually go.

**Prerequisites:** [Day 4](../../day4/lab/lab.md) complete.

---

## 1. You've already been following this convention

Every lab in this course so far has split one folder into the same handful of files:

| File | Contains |
|------|----------|
| `providers.tf` | `terraform {}` block, `required_providers`, `provider` blocks |
| `variables.tf` | Every `variable` declaration |
| `locals.tf` | Every `locals {}` block |
| `main.tf` | The actual `resource`/`data` blocks |
| `outputs.tf` | Every `output` declaration |

**Terraform doesn't require this split** — it reads every `.tf` file in a directory as one
combined configuration, in no particular order (Day 3 Topic 2, §6 said this too). The split is
purely for **humans**: anyone opening this repo already knows where to look for "what can I
configure" (`variables.tf`) versus "what does this actually build" (`main.tf`) without reading
every line.

---

## 2. Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Resource local names | `snake_case`, descriptive, no resource-type repetition | `aws_s3_bucket.app_data` not `aws_s3_bucket.aws_s3_bucket_app_data` |
| Variable names | `snake_case`, matches what it configures | `project_prefix`, `environment` |
| Real AWS resource names (the `name`/`bucket` argument) | Built from a shared prefix, never hardcoded literally | `local.name_prefix` (Day 3 Topic 1) |
| Tags | One shared map applied everywhere | `local.common_tags`, used in every lab since Day 3 |

Consistent naming is what makes `terraform state list` and `terraform plan` output skimmable at a
glance instead of a wall of similar-looking noise.

---

## 3. Tagging strategy

Every resource this course creates gets the same tag shape via `local.common_tags` — `Project`,
`Environment`, `Owner`, `Day`. In a real organization, tags typically also carry:
- **Cost allocation** (`CostCenter`, `Team`) — so a monthly AWS bill can be broken down by who
  owns what, without guessing from resource names.
- **Compliance/lifecycle** (`DataClassification`, `Backup`) — so automated tooling (backup jobs,
  compliance scanners) can act on tags instead of hardcoded resource lists.
- A **mandatory minimum tag set**, often enforced organization-wide via an SCP or AWS Config rule
  — untagged resources are one of the most common causes of "who owns this and can we delete it?"
  archaeology.

---

## 4. Growing beyond one folder

A single flat folder (what every lab so far has been) works until a project needs more than one
independently-deployed unit. The two patterns you'll meet later in this course:

```
project/
├── modules/              ← reusable building blocks (Day 9)
│   ├── vpc/
│   └── compute/
└── environments/          ← one deployable root config per environment (the capstone)
    ├── dev/
    ├── qa/
    └── prod/
```

- **`modules/`** — code you write once and call multiple times with different inputs (a VPC
  shape, a compute tier). Not deployed directly.
- **`environments/`** (or workspaces — Day 11 covers the trade-off) — the actual root
  configurations that call those modules with environment-specific values, each with its **own**
  state file, so a mistake in `dev` can never touch `prod`.

You aren't building this yet — Day 9 (modules) and the capstone (environments) get there — but
recognizing the shape now means Day 9 won't feel like a new idea, just a name for something
you've already anticipated.

---

## 5. Documentation & repo hygiene

- **A `README.md` per module/project** explaining what it builds, its inputs, and its outputs —
  `terraform-docs` (a separate CLI tool) can generate this automatically from your `variables.tf`/
  `outputs.tf` descriptions, which is exactly why every variable and output in this course has a
  `description`.
- **`.gitignore`** — this repo's own `.gitignore` is the reference: block `.terraform/`,
  `*.tfstate*`, `*.tfvars` (except `*.tfvars.example`), `.terraformrc`, credentials. See Topic 2
  for the `.tfvars`/`.tfvars.example` half of this.
- **One resource, one clear reason to exist** — if you can't explain why a resource is in a
  config in one sentence, that's a sign it belongs in a different module or shouldn't exist yet.

---

## Small illustrative snippet

See [`examples/suggested_layout.txt`](./examples/suggested_layout.txt) for a fuller example tree,
annotated line by line, showing how a project grows from "one folder" (where you are today) to
"modules + environments" (where the capstone ends up).

---

## Checklist
- [ ] I can explain why `.tf` files are split by concern even though Terraform doesn't require it
- [ ] I can explain this course's tagging convention and why cost/compliance tags matter in a real org
- [ ] I can describe the difference between `modules/` and `environments/` in one sentence each

Next: **[Topic 2 — `terraform.tfvars`](../2.%20terraform_tfvars/terraform_tfvars.md)**.
