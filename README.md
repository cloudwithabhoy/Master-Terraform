# Master Terraform on AWS — Zero to Job-Ready

A hands-on, day-by-day training program for engineers who are **new to both AWS and Terraform**.
No prior cloud or infrastructure-as-code experience is assumed.

> Maintained by a senior DevOps engineer for onboarding junior engineers.
> Work through it in order — each day builds on the last.

---

## Who this is for

You, if:
- You have never used AWS (or have only clicked around the console once or twice).
- You have never written Terraform.
- You are comfortable using a terminal and editing text files.

By the end you will be able to build real, production-shaped AWS infrastructure from code,
review a teammate's Terraform, and understand what `plan`/`apply` are about to do to a live account.

---

## How each day is structured

> **Two folder conventions in this repo.** Days 1-2 use `Day N-topic-slug/` (capitalized) — that
> convention is frozen and won't change. **Day 3 onward** uses `dayN/` (lowercase), teaching **2-5
> topics in depth per day**, each in its own numbered subfolder. Days 3-5 pair this with **one
> shared lab per day** that ties every topic together — not one lab per topic. **Days 6-8 skip
> the shared lab entirely** — each topic's own `examples/` is real, applyable, and self-contained
> instead. There's no `exercises.md`/`solutions/` step either way — the practice is the day's
> `lab/` (where one exists) plus each topic's `examples/`.

**Days 1-2:**
```
Day N-topic-slug/
├── topic-slug.md  ← concept doc: read this FIRST
└── lab/           ← hands-on Terraform you actually run (hands-on days)
```

**Day 3 onward:**
```
dayN/
├── 1. topic_slug_a/
│   ├── topic_slug_a.md  ← concept doc for this topic (Terraform mechanics), in depth
│   └── examples/        ← small standalone .tf snippets illustrating just this topic
├── 2. topic_slug_b/
│   └── ...              ← same shape, this day's 2nd (or 3rd) topic
├── aws_<resource>.md    ← AWS-service deep dive, basic → advanced (flat file, e.g. aws_s3.md)
└── lab/                 ← ONE shared, hands-on lab combining every topic in this day
```

Topic subfolders are numbered (`1.`, `2.`, ...) in the order they're meant to be done. Every day
that introduces a new AWS service gets a companion `aws_<resource>.md` — a flat file at the day's
root — explaining the **AWS service itself** (independent of Terraform, basic through advanced),
while each topic doc stays focused on the **Terraform mechanics** of managing that service. Days
with no new AWS service (like Day 6's language-mechanic trio, or Day 7/8 now that their AWS deep
dives were removed) skip this file entirely.

The rhythm for a day:
1. **Read** the AWS deep dive (if the day has one), then each topic's concept doc in numbered
   order, working through its `examples/` as you go.
2. **Run** the day's shared `lab/` if it has one (Days 3-5), command by command, applying every
   topic together on real AWS resources — otherwise (Days 6-8) each topic's own `examples/` already
   is the hands-on practice.
3. **Destroy** everything you created (see the Golden Rules below).

---

## Curriculum

> **8 days total**, ~2 hours each, covering every AWS + Terraform concept in the program. **All
> 8 days are built.** A separate, standalone **capstone CI/CD project** (dev/qa/prod via GitHub
> Actions) is next.

| Day | Topics | You'll build | New Terraform ideas |
|----:|--------|--------------|---------------------|
| [1](./Day%201-basics/aws-terraform-basics.md) | AWS & Terraform basics | (concepts — the mental model) | IaC, providers, resources, state, the workflow |
| [2](./Day%202-setup/setup-aws-terraform.md) | Setup AWS & Terraform | AWS account + IAM user + billing alarm + smoke-test lab | Install & configure Terraform + AWS CLI |
| 3 | [1. Variables, locals & outputs](./day3/1.%20variables/variables.md) · [2. First resource](./day3/2.%20first_resource/first_resource.md) · [AWS: S3 deep dive](./day3/aws_s3.md) | Your first S3 bucket, fully variable-driven | `variable`, `locals`, `output`, `data` sources, `init/plan/apply/destroy` against AWS |
| 4 | [1. Version constraints](./day4/1.%20version_constraints/version_constraints.md) · [2. IAM as code](./day4/2.%20iam_as_code/iam_as_code.md) · [AWS: IAM deep dive](./day4/aws_iam.md) | An IAM role + scoped S3-read policy, built under explicit version pins | `required_version`/`required_providers`, `~>`, `jsonencode`/`aws_iam_policy_document`, role trust vs. permission policies |
| 5 | [1. Project structure](./day5/1.%20project_structure/project_structure.md) · [2. terraform.tfvars](./day5/2.%20terraform_tfvars/terraform_tfvars.md) | A small VPC module, deployed to `dev` and `qa` via `.tfvars` (previews modules) | `.tfvars`/`.tfvars.example`, recommended repo layout, first look at a `module` block |
| 6 | [1. for_each](./day6/1.%20for_each/for_each.md) · [2. count](./day6/2.%20count/count.md) · [3. depends_on](./day6/3.%20depends_on/depends_on.md) | Real EC2 instances built both ways in each topic's own runnable example — no separate shared lab | `for_each`, `count`, `depends_on` |
| 7 | [1. Dynamic blocks](./day7/1.%20dynamic_block/) · [2. Conditional expressions](./day7/2.%20conditional_expressions/conditional_expressions.md) · [3. Terraform functions](./day7/3.%20terraform_functions/terraform_functions.md) · [4. Lifecycle rules](./day7/4.%20lifecycle_rules/lifecycle_rules.md) | EC2 web servers (fleet sized via `count`, learned Day 6); security-group rules generated from a list; `prevent_destroy`/`ignore_changes` in action | `user_data`, AMIs, `condition ? a : b`, `dynamic`, `merge`/`lookup`/`join`/`try`/`jsonencode`, `lifecycle` |
| 8 | [1. State management](./day8/1.%20state_management/state_management.md) · [2. Modules](./day8/2.%20modules/modules.md) · [3. `terraform import`](./day8/3.%20terraform_import/terraform_import.md) · [4. Drift detection](./day8/4.%20drift_detection/drift_detection.md) | Shared remote state; a VPC + compute pattern refactored into modules, called twice; a hand-created bucket imported; drift caused and detected | S3 backend + DynamoDB lock, `terraform_remote_state`, authoring & calling modules, `import` blocks + `-generate-config-out`, `plan -refresh-only` |

**After Day 8:** a standalone capstone — a 5-6 resource full stack deployed to **dev/qa/prod**
via **GitHub Actions** CI/CD (plan on PR, gated apply per environment). Scoped in detail once
Day 8 is reached.

---

## Prerequisites (before Day 1)

- A computer running macOS, Linux, or Windows (WSL2 recommended on Windows).
- A personal email and a **credit/debit card** (required to open an AWS account — you will stay within the Free Tier).
- A code editor — [VS Code](https://code.visualstudio.com/) with the HashiCorp Terraform extension.

Everything else (installing Terraform, the AWS CLI, creating the account) is walked through in **[Day 2](./Day%202-setup/setup-aws-terraform.md)**.

---

## Golden Rules — read these before you touch AWS

AWS charges real money. These rules keep the bill near **$0**.

1. **Set up a billing alarm on Day 2.** Non-negotiable.
2. **`terraform destroy` at the end of every session.** If you built it today, tear it down today.
3. **Stay in one region.** We use `us-east-1` throughout unless told otherwise.
4. **Never commit secrets.** No access keys, no `.tfstate`, no `.tfvars` with secrets. The `.gitignore` protects you — don't fight it.
5. **Free Tier is not unlimited.** Big instance types, NAT Gateways, and RDS left running overnight cost money. When in doubt, destroy.
6. **Ask before you `apply` something you don't understand.** Read the plan output. Every line.

---

## Getting help

- Terraform docs: https://developer.hashicorp.com/terraform/docs
- AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Stuck? Bring the **exact** error text and your `plan` output to your mentor.
