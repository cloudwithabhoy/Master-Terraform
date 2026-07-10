# AWS & Terraform setup

## What you need before starting
- A computer (macOS, Linux, or Windows — WSL2 recommended on Windows).
- An AWS account and IAM user access keys ready to use.
- ~20–30 minutes.

---

## 1. Install the tools (20 min)

### AWS CLI
- **macOS:** `brew install awscli`
- **Windows:** installer → https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **Linux:** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Download the installer package for your OS, run it, then open a terminal and verify:
```bash
aws --version
# aws-cli/2.x.x ...
```

### Terraform
- **macOS:** `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
- **Windows:** `choco install terraform` or manual install below
- **Linux:** https://developer.hashicorp.com/terraform/install

**Manual install on Windows (no Chocolatey):**
1. Download the Terraform zip from https://developer.hashicorp.com/terraform/install — it lands
   in your `Downloads` folder.
2. Unzip it — this gives you `terraform.exe` and a license file (e.g. `LICENSE.txt`).
3. Create a folder `C:\terraform`.
4. Cut both `terraform.exe` and the license file from `Downloads` and paste them into
   `C:\terraform`.
5. Copy the folder path (`C:\terraform`).
6. Add it to your **PATH**: search **"Environment Variables"** in Windows → **Edit the system
   environment variables** → **Environment Variables** → under **System variables**, select
   **Path** → **Edit** → **New** → paste `C:\terraform` → **OK** on all dialogs.
7. Close and reopen your terminal so the updated PATH takes effect.

Verify:
```bash
terraform -version
# Terraform v1.x.x
```

### VS Code (recommended)
Install [VS Code](https://code.visualstudio.com/) and the **HashiCorp Terraform** extension for
syntax highlighting and autocomplete.

---

## 2. Connect the AWS CLI to your account (5 min)

```bash
aws configure
```
Enter the four values:
```
AWS Access Key ID     : <your Access Key ID>
AWS Secret Access Key : <your Secret Access Key>
Default region name   : us-east-1
Default output format : json
```
This saves your credentials to `~/.aws/credentials`. **Terraform reads these automatically** —
you will never put keys in your `.tf` files.

---

## 3. Hands-on verification (required)

Run these. Each must succeed before you move on.

**1. AWS CLI can see your account:**
```bash
aws sts get-caller-identity
```
You should get JSON with your account number and your IAM user ARN.

**2. Terraform is installed:**
```bash
terraform -version
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `aws: command not found` | CLI didn't install or isn't on PATH. Reopen terminal; re-run installer. |
| `Unable to locate credentials` | You skipped/mistyped `aws configure`. Run it again. |
| `InvalidClientTokenId` | Access key is wrong or was deleted. Make a fresh key in IAM, re-run `aws configure`. |
| `terraform: command not found` | Reopen terminal; re-check the Terraform install steps. |
| `Error: no valid credential sources` (from Terraform) | Same as above — fix `aws configure` first, confirm with `aws sts get-caller-identity`. |
