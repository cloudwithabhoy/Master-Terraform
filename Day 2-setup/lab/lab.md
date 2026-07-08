# Lab — Setup Check: Create a Small VPC

**Goal:** Prove your whole setup works — Terraform is installed, the AWS provider downloads, and
your `aws configure` credentials can actually create real infrastructure — by creating a small
VPC and then destroying it.

> Cost: an empty VPC is **free**. Just run `terraform destroy` at the end so nothing lingers.

**Do this after** you've finished steps 1-5 in
[`../setup-aws-terraform.md`](../setup-aws-terraform.md) (account created, `aws configure` done).

---

## The file in this folder

Everything is in a single file:

| File | What it contains |
|------|------------------|
| `main.tf` | Terraform settings + AWS provider + one `aws_vpc` resource + one output. |

Open it and read the comments before running - it explains every line.

---

## How to run the lab

### Step 0 — Move into this folder
From the repository root:
```bash
cd "Day 2-setup/lab"
```
> The quotes matter because the folder name has a space in it.

### Step 1 — `terraform init`
```bash
terraform init
```
Downloads the AWS provider and sets up the working directory. Run once per project.
Expect: `Terraform has been successfully initialized!`

### Step 2 — `terraform plan`
```bash
terraform plan
```
Previews the change **without making it**. Read it - you should see the VPC marked with `+`
(create) and the summary:
```
Plan: 1 to add, 0 to change, 0 to destroy.
```

### Step 3 — `terraform apply`
```bash
terraform apply
```
Terraform shows the plan again and asks `Do you want to perform these actions?` - type
**`yes`**. When it finishes you'll see:
```
Outputs:

vpc_id = "vpc-0abc123def4567890"
```
If you see a real `vpc_id`, **your entire setup works.**

### Step 4 — Confirm it exists
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=master-terraform-day2-example" \
  --query "Vpcs[].VpcId" --output text
```
This prints the same VPC id. (Or find it in the VPC console in your browser.)

### Step 5 — `terraform destroy`
```bash
terraform destroy
```
Type **`yes`**. Terraform deletes the VPC. Build this habit now - always end a lab clean.

---

## What just happened
- `terraform init` downloaded the AWS provider plugin.
- `terraform plan` previewed the change.
- `terraform apply` created a real VPC using your credentials.
- `terraform destroy` removed it.

You just ran the full Terraform workflow from Day 1 for the first time, against your own AWS
account.

---

## Troubleshooting

| Message | Fix |
|---------|-----|
| `Error: No valid credential sources found` | Credentials not set. Run `aws configure`, then confirm with `aws sts get-caller-identity`. |
| `InvalidClientTokenId` / `SignatureDoesNotMatch` | Access key is wrong or was deleted. Create a fresh key in IAM and re-run `aws configure`. |
| `terraform: command not found` | Terraform isn't installed / not on PATH. Revisit step 4 of the setup guide. |
| `UnauthorizedOperation` creating the VPC | Your IAM user lacks permissions - confirm it has `AdministratorAccess` (setup step 3). |
| `Error: Failed to install provider` | No internet, or a proxy is blocking the registry. Check your connection. |

When this lab creates a VPC and you then destroy it, tick the setup-check box on the Day 2
checklist - you're done.
