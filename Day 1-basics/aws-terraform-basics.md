# Day 1 — AWS & Terraform Basics

**Goal:** Build the mental model. Understand *what* the cloud, AWS, Infrastructure as Code,
and Terraform are — and *why* we use them — before touching a keyboard.

> This is the concepts day (delivered in class). No installation yet — that's **Day 2**.
> Use this README as your recap and reference. Do the concept-check at the end.

---

## 1. What is "the cloud" and AWS? (read)

Traditionally, running software meant **buying physical servers**, racking them in a room,
powering and cooling them, and maintaining them yourself. Slow, expensive, hard to scale.

**Cloud computing** flips that: you **rent** computing resources — servers, storage,
networking, databases — from a provider, over the internet, and **pay only for what you use**.
Need 10 more servers for an hour? Click (or code) and they appear; delete them and you stop
paying.

**AWS (Amazon Web Services)** is the largest cloud provider. It offers ~200 **services**, each
solving one need. The handful we'll actually use in this course:

| Service | What it gives you | Real-world analogy |
|---------|-------------------|--------------------|
| **IAM** | Identities & permissions | The security desk: who's allowed in, and where |
| **S3** | Object (file) storage | An infinite, durable Dropbox |
| **EC2** | Virtual servers | A computer you rent by the second |
| **VPC** | Your private network | The office building's walls & doors |
| **RDS** | Managed databases | A DBA-in-a-box |

You create these resources in a **region** (e.g. `us-east-1` = N. Virginia) — a geographic
location. We'll standardize on **`us-east-1`** for the whole course.

---

## 2. Two ways to create cloud resources

### The click way (the console)
You log into the AWS website and click buttons to create things. Fine for exploring, but:
- not repeatable — did you click the exact same 30 things last time?
- not reviewable — no diff, no pull request, no history
- not shareable — "works on my account" but nobody knows how
- error-prone and slow at scale

### The code way (Infrastructure as Code)
You **write down** what you want in text files and let a tool build it. This is
**Infrastructure as Code (IaC)**. Benefits:
- **Repeatable** — same code → same infrastructure, every time
- **Versioned** — it's in git; you can see who changed what, and roll back
- **Reviewable** — teammates review infra changes like any code
- **Self-documenting** — the code *is* the documentation of what exists

> The whole point of this course is to move you from *clicking* to *coding* your infrastructure.

---

## 3. What is Terraform?

**Terraform** (by HashiCorp) is the most widely used IaC tool. You describe your desired
infrastructure in files ending in **`.tf`**, written in a language called **HCL** (HashiCorp
Configuration Language). Terraform then makes the real cloud match what you wrote.

Terraform is **declarative**: you say *what* you want to exist ("an S3 bucket named X"), not
the step-by-step *how*. Terraform figures out the how — what to create, update, or delete to
reach your desired state.

It's also **multi-cloud**: the same tool works with AWS, Azure, GCP, and hundreds of other
platforms via **providers**. We use the **AWS provider**.

---

## 4. The core workflow (memorize this)

This loop is the heartbeat of everything we do, every single day:

```
  write .tf   →   terraform init   →   terraform plan   →   terraform apply   →   terraform destroy
 (what you        (download the        (preview the         (make it real,        (tear it all
  want, in HCL)    provider plugin)     changes — a diff)     after you approve)    down when done)
```

- **`init`** — downloads the provider plugins the config needs. Run once per project.
- **`plan`** — shows you *exactly* what Terraform will add / change / destroy, **without doing
  it**. You always read this before applying.
- **`apply`** — executes the plan and creates/updates the real resources (asks you to confirm).
- **`destroy`** — deletes everything the config manages. Our daily cleanup, so we never get a
  surprise bill.

---

## 5. The vocabulary you'll hear constantly

| Term | Meaning |
|------|---------|
| **HCL** | The language Terraform files are written in. Human-readable, block-based. |
| **Provider** | A plugin that teaches Terraform how to talk to a platform (e.g. `aws`). |
| **Resource** | One thing you want to exist, e.g. `aws_s3_bucket`. The core building block. |
| **Data source** | A read-only *lookup* of something that already exists. Creates nothing. |
| **State** | Terraform's record of what it actually created (`terraform.tfstate`). Its memory. |
| **Variable** | An input to your config, so it's not all hard-coded. |
| **Output** | A value your config returns after apply (e.g. a server's IP). |
| **Module** | A reusable, packaged group of resources. (Later in the course.) |

### What a tiny bit of HCL looks like
You'll write blocks like this (don't run anything yet — just read it):

```hcl
# Tell Terraform we want the AWS provider, and where to work.
provider "aws" {
  region = "us-east-1"
}

# Declare one resource: an S3 bucket.
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-first-bucket-12345"
}
```

- `resource` = the keyword.
- `"aws_s3_bucket"` = the **type** of thing (defined by the AWS provider).
- `"my_bucket"` = a **local name** you invent, to refer to it elsewhere in your code.
- Inside `{ }` = the settings for that resource.

---

## 6. The one rule that keeps this free

AWS charges **real money**. Throughout this course:

> **Golden Rule:** if you `apply` something today, you `destroy` it before you leave.

We'll set up a billing alarm on Day 2 as a safety net, and we'll stay inside the AWS **Free
Tier**. Follow the rule and this whole course costs roughly **$0**.

---

## Concept check (do these on your own)

Answer in your own words — no computer needed:

1. In one sentence, what problem does Infrastructure as Code solve that clicking in the console
   doesn't?
2. What does each command do: `init`, `plan`, `apply`, `destroy`?
3. What is the difference between a **resource** and a **data source**?
4. What is Terraform **state**, and why does Terraform need it?
5. Why is "declarative" (say *what* you want) different from writing a script that says *how*?
6. What is the Golden Rule, and why does it matter for your AWS bill?

> If you can answer all six comfortably, you're ready for **Day 2 — Setup**, where we create
> your AWS account and install the tools.
