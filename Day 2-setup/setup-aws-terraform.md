# Day 2 — Setup AWS & Terraform

**Goal:** Get a working setup: an AWS account, a safe IAM user for daily work, a **billing
alarm** so you never get a surprise bill, and **Terraform + AWS CLI installed and talking to
your account**.

**Prerequisites:** [Day 1 basics](../Day%201-basics/aws-terraform-basics.md). You should know
what AWS, Terraform, and the `init/plan/apply/destroy` workflow are.

> This is a hands-on "set up your workshop" day. By the end, your machine can create real AWS
> infrastructure with Terraform. The **hands-on verification at the bottom is required.**

---

## What you need before starting
- A computer (macOS, Linux, or Windows — WSL2 recommended on Windows).
- A personal email and a **credit/debit card** (AWS requires one to open an account; we stay in
  the Free Tier — expect ~$0).
- ~45–60 minutes.

---

## 1. Create your AWS account (15 min)

1. Go to https://aws.amazon.com/ → **Create an AWS Account**.
2. Enter your email, an account name, and a strong root password.
3. Enter your address and a **credit/debit card**. AWS may place a temporary ~$1 hold to verify
   it — this is refunded.
4. Choose the **Basic (free) support plan**.
5. Verify your phone number.

> The email + password you just created is the **root user**. It can do *anything* on the
> account. We use it as little as possible — only for account-level settings. For daily work we
> create a limited IAM user in step 3.

### Secure the root user with MFA (do it now)
- Sign in as root → search **IAM** → **Add MFA** → use an authenticator app (Google
  Authenticator, Authy, 1Password, etc.). This stops anyone with just your password from getting
  in.

---

## 2. Set up a billing alarm (10 min) — DO NOT SKIP

Your safety net. It emails you if spending crosses a threshold.

1. Signed in as root → **Billing and Cost Management** → **Billing preferences**.
2. Enable **"Receive Free Tier usage alerts"** and enter your email.
3. **Budgets** → **Create budget** → **Use a template** → **"Monthly cost budget"**.
4. Set the amount to **$5**, enter your email, and create it.

You'll now get an email long before anything meaningful is charged.

---

## 3. Create an IAM user for daily work (15 min)

We don't use the root account day-to-day. Create a normal user with admin rights **for
learning** (in a real job you'd scope this down tightly).

1. Sign in as root → **IAM** → **Users** → **Create user**.
2. User name: `terraform-admin` (or your name).
3. Permissions → **Attach policies directly** → check **`AdministratorAccess`**.
   > In production you'd *never* hand out `AdministratorAccess`. For a personal learning
   > account it's acceptable so you don't fight permissions while learning.
4. Create the user.

### Create an access key (this is what Terraform uses)
1. Open the new user → **Security credentials** tab → **Create access key**.
2. Choose **Command Line Interface (CLI)**, acknowledge, and create.
3. You'll see an **Access key ID** and a **Secret access key**.
   **This is the only time the secret is shown.** Copy both somewhere safe temporarily.

> These two strings are like a username + password for your entire account. Never paste them
> into code, never commit them to git, never share them. If one ever leaks, delete it
> immediately in the IAM console and make a new one.

---

## 4. Install the tools (20 min)

### AWS CLI
- **macOS:** `brew install awscli`
- **Windows:** installer → https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **Linux:** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Verify:
```bash
aws --version
# aws-cli/2.x.x ...
```

### Terraform
- **macOS:** `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
- **Windows:** `choco install terraform` or download → https://developer.hashicorp.com/terraform/install
- **Linux:** https://developer.hashicorp.com/terraform/install

Verify:
```bash
terraform -version
# Terraform v1.x.x
```

### VS Code (recommended)
Install [VS Code](https://code.visualstudio.com/) and the **HashiCorp Terraform** extension for
syntax highlighting and autocomplete.

---

## 5. Connect the AWS CLI to your account (5 min)

```bash
aws configure
```
Enter the four values:
```
AWS Access Key ID     : <the Access key ID from step 3>
AWS Secret Access Key : <the Secret access key from step 3>
Default region name   : us-east-1
Default output format : json
```
This saves your credentials to `~/.aws/credentials`. **Terraform reads these automatically** —
you will never put keys in your `.tf` files.

---

## 6. Hands-on verification (required)

Run these. Each must succeed before you move on.

**1. AWS CLI can see your account:**
```bash
aws sts get-caller-identity
```
You should get JSON with your account number and the `terraform-admin` user ARN.

**2. Terraform is installed:**
```bash
terraform -version
```

**3. Terraform can reach AWS.** We've prepared a tiny lab for this in the [`lab/`](lab/)
folder — a single `main.tf` that creates one small **VPC** (a private network). An empty VPC is
**free**, and you destroy it right after. Full step-by-step instructions are in
**[`lab/lab.md`](lab/lab.md)**. In short:

```bash
cd "Day 2-setup/lab"
terraform init      # downloads the AWS provider
terraform apply     # type "yes" — creates one free VPC
terraform destroy   # type "yes" — removes it (always clean up)
```

If the output shows a real `vpc_id` (like `vpc-0abc123...`), **your whole setup works.**

> What just happened: `init` downloaded the AWS provider plugin, and `apply` created a real
> (but free) VPC using your credentials. You just ran the full Terraform workflow from Day 1 for
> the first time. The comments in `main.tf` explain every line — read them.

---

## Day 2 checklist
- [ ] AWS account created; root user has **MFA**
- [ ] Free Tier alerts + a **$5 budget** created
- [ ] IAM user `terraform-admin` created with an access key
- [ ] `aws --version` and `terraform -version` both work
- [ ] `aws sts get-caller-identity` returns my account
- [ ] The Terraform setup-check created a VPC (printed a `vpc_id`) and I destroyed it
- [ ] I understand I must never commit access keys

When every box is checked, your workshop is ready. **Next up (coming soon): Day 3 — your first
real resource**, where you run the full `plan → apply → destroy` loop against AWS.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `aws: command not found` | CLI didn't install or isn't on PATH. Reopen terminal; re-run installer. |
| `Unable to locate credentials` | You skipped/mistyped `aws configure`. Run it again. |
| `InvalidClientTokenId` | Access key is wrong or was deleted. Make a fresh key in IAM, re-run `aws configure`. |
| `terraform: command not found` | Reopen terminal; re-check the Terraform install steps. |
| `Error: no valid credential sources` (from Terraform) | Same as above — fix `aws configure` first, confirm with `aws sts get-caller-identity`. |
