# Day 4, Topic 2 — IAM as Code

**Goal:** Learn the Terraform mechanics of declaring an IAM role and policy — trust policies,
permission policies, `jsonencode()` vs. the `aws_iam_policy_document` data source, and attaching a
policy to a role.

**Prerequisites:** [Topic 1 — Version Constraints](../1.%20version_constraints/version_constraints.md)
read first, and [Day 3](../../day3/lab/lab.md) complete.

> This doc is about **Terraform mechanics**. For what IAM itself actually is (users/roles/
> policies, evaluation logic, permission boundaries, federation — basic to advanced), read
> **[`aws_iam.md`](../aws_iam.md)** alongside or before this. Today's
> **[shared lab](../lab/lab.md)** builds a real role using this topic and Topic 1 (version
> constraints) together.

---

## 1. What IAM is, briefly (full depth in `aws_iam.md`)

**IAM** controls who/what can do what in your AWS account. A **role** is an identity assumed
temporarily — by a person, an AWS service like EC2, or another account — with no long-lived
credentials. A **trust policy** says *who can assume the role*; a **permission policy** says
*what the role can do once assumed*. Confusing these two is the #1 IAM error beginners make — see
[`aws_iam.md` §2-3](../aws_iam.md#2-core-identity-types-basic) for the full picture before
continuing.

---

## 2. Writing a policy document in Terraform

You can write policy JSON by hand with `jsonencode()`:

```hcl
resource "aws_iam_role" "app_role" {
  name = "my-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
```

...or use the `aws_iam_policy_document` **data source**, which builds the same JSON from HCL
blocks — less error-prone (typed, validated) and what today's lab uses:

```hcl
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_role" {
  name               = "my-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
```

Both produce identical JSON. Prefer the data source when you're writing the policy yourself;
reach for `jsonencode()` when you're pasting a policy someone already gave you as JSON. See
[`examples/policy_document_vs_jsonencode.tf`](./examples/policy_document_vs_jsonencode.tf) for
both side by side.

---

## 3. Attaching a policy to a role

Creating a role and a policy separately does **nothing** until you explicitly attach one to the
other:

```hcl
resource "aws_iam_policy" "s3_read_only" {
  name   = "my-role-s3-read-only"
  policy = data.aws_iam_policy_document.s3_read_only.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}
```

A role can have **multiple** policies attached — its effective permissions are the union of all
of them, evaluated the way [`aws_iam.md` §4](../aws_iam.md#4-how-aws-evaluates-am-i-allowed-to-do-this-intermediate--memorize-this-order)
describes (explicit deny anywhere wins; otherwise default is implicit deny until something
explicitly allows it). See
[`examples/attach_multiple_policies.tf`](./examples/attach_multiple_policies.tf).

---

## 4. Common Terraform mistakes (so you can avoid them)

- **Forgetting `aws_iam_role_policy_attachment`** — creating a role and a policy separately does
  nothing until you explicitly attach the policy to the role.
- **Hardcoding your account ID** — use `data.aws_caller_identity.current.account_id` instead; it
  keeps the code portable across accounts.
- **Putting real secrets in a variable's `default`** — defaults get committed to git. Use
  `*.tfvars` (gitignored) or environment variables for anything sensitive.
- **`"Action": "*"` on `"Resource": "*"`** — works, but violates least privilege (see
  [`aws_iam.md` §9](../aws_iam.md#9-least-privilege-in-practice-the-theme-across-all-of-this)).
  Always scope to the specific actions and ARNs you actually need.

---

## Checklist
- [ ] I can explain trust policy vs. permission policy in my own words
- [ ] I can write a trust policy with `aws_iam_policy_document`
- [ ] I used a `data` source and understand it creates nothing
- [ ] I understand why attaching a policy to a role is a separate step

Next: today's **[shared lab](../lab/lab.md)** — build a real IAM role using this topic and
Topic 1 (version constraints) together.
