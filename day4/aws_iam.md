# AWS Resource Deep Dive — IAM (Identity and Access Management)

> This doc is about **IAM itself** — the AWS service, independent of Terraform. For how to
> *manage* IAM with Terraform, see [`iam_as_code.md`](2.%20iam_as_code/iam_as_code.md).
> Basic → advanced, in order. Skim ahead if you already know a section.

---

## 1. What IAM is, in one sentence

IAM controls **who** (or **what**) can do **what** to **which resources** in your AWS account —
every single API call to every AWS service passes through an IAM authorization check first.

---

## 2. Core identity types (basic)

| Type | Lifespan | Used for |
|------|----------|----------|
| **Root user** | Permanent, tied to the account email | Nothing, day to day — lock it away, enable MFA, never use it except for the handful of tasks that require it (e.g. closing the account). |
| **IAM User** | Long-lived | A named identity for a person or a legacy application. Can have a password (console) and/or access keys (API/CLI). |
| **IAM Group** | N/A (not an identity) | A named bundle of users, so you attach policies once to the group instead of to each user. |
| **IAM Role** | Temporary (assumed) | An identity with **no long-lived credentials** — assumed by a user, an AWS service (EC2, Lambda), or another AWS account, receiving short-lived, auto-rotating credentials via STS. |

**Modern best practice:** minimize long-lived IAM users with access keys entirely. Humans should
authenticate via **IAM Identity Center** (SSO) and assume roles; workloads (EC2, Lambda, ECS)
should use roles, never embedded access keys.

---

## 3. Policies — the actual permission documents (basic)

A **policy** is a JSON document with one or more **statements**. Each statement has:

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:ListBucket"],
  "Resource": "arn:aws:s3:::my-bucket/*",
  "Condition": { "StringEquals": { "aws:PrincipalTag/team": "platform" } }
}
```

| Field | Meaning |
|-------|---------|
| **Effect** | `Allow` or `Deny`. |
| **Action** | Which API call(s) this statement covers, e.g. `s3:GetObject`, `ec2:*`. |
| **Resource** | Which ARN(s) this applies to. `*` means "any resource" — avoid unless truly needed. |
| **Principal** | *(resource-based policies only)* — **who** this statement applies to. Identity-based policies (attached to a user/role) don't need this; it's implicit. |
| **Condition** | *(optional)* — extra constraints: source IP, MFA present, time of day, tags, etc. |

### Policy types
- **Identity-based** — attached to a user/group/role. "This identity can do X."
- **Resource-based** — attached to the resource itself (S3 bucket policy, KMS key policy, SQS
  queue policy). "This resource can be accessed by X." The *only* way to grant cross-account
  access without the other account assuming a role.
- **AWS managed policies** — pre-built by AWS (e.g. `AdministratorAccess`, `ReadOnlyAccess`).
  Convenient, but not scoped to your specific needs.
- **Customer managed policies** — you write and own them; reusable across multiple identities;
  the recommended approach for anything beyond a quick lab.
- **Inline policies** — embedded directly in one user/role/group, not reusable. Generally avoid
  in favor of customer-managed policies, except for one-off, tightly-coupled permissions.

---

## 4. How AWS evaluates "am I allowed to do this?" (intermediate — memorize this order)

For every request, AWS combines **every applicable policy** (identity-based, resource-based,
permission boundaries, SCPs, session policies) and evaluates in this order:

1. **Explicit Deny anywhere → Deny.** Full stop, nothing else matters.
2. **Organizations SCP must Allow** (if the account is in an AWS Organization) — an SCP that
   doesn't allow an action makes it **implicitly denied**, no matter what the IAM policy says.
3. **Permission boundary must Allow** (if one is attached to the role/user) — same idea, one
   level down: a boundary caps the *maximum* permissions a policy can grant.
4. **Identity-based OR resource-based policy must Allow.** If neither explicitly allows it →
   **implicit deny (the default)**.

**The single most common beginner mistake:** assuming "no policy mentions it, so it must be
denied *for a specific reason*" — no, the default for everything in AWS is **implicit deny**;
nothing is allowed unless something explicitly allows it.

---

## 5. Assuming roles & STS (intermediate)

- **STS (Security Token Service)** issues temporary credentials (access key, secret key, session
  token) with an expiration, typically 15 minutes to 12 hours.
- **`sts:AssumeRole`** — the action that lets one identity become a role, subject to that role's
  **trust policy** explicitly naming the assuming principal (a user, role, account, or AWS
  service).
- Common patterns: an EC2 instance profile assuming a role (what today's lab builds), a human
  assuming a higher-privilege role only when needed ("just-in-time" access), or one AWS account
  assuming a role in another account (cross-account access without sharing credentials).

---

## 6. Permission boundaries vs. SCPs (advanced — both cap permissions, different scope)

| | **Permission boundary** | **SCP (Service Control Policy)** |
|---|---|---|
| Attached to | One IAM user or role | An entire AWS Organization / OU / account |
| Sets a... | Maximum for that one identity | Maximum for every identity in that account, including the root user |
| Typical use | "This role can never exceed X, even if someone attaches a broader policy later" (delegated admin safety) | "No account in this OU may ever use region X" or "never disable CloudTrail," org-wide |

Neither one **grants** anything by itself — both only **cap** what identity-based policies can
otherwise allow. A permission boundary or SCP with no matching Allow in the actual policy still
results in denied access.

---

## 7. Federation & IAM Identity Center (advanced)

- **Federation** — authenticate outside AWS (corporate Active Directory, Google Workspace, Okta)
  and get temporary AWS credentials without ever creating an IAM user, via SAML 2.0 or OIDC.
- **IAM Identity Center** (formerly AWS SSO) — AWS's own solution for this: one login for your
  workforce, mapped to roles ("permission sets") in one or many AWS accounts. This is what
  replaces "everyone gets an IAM user with a password" at any organization beyond a handful of
  people.
- **OIDC federation for CI/CD** — GitHub Actions, GitLab CI, etc. can assume an AWS role directly
  via OIDC, with zero long-lived AWS credentials stored in your CI system at all. Directly
  relevant to this course's later CI/CD capstone.

---

## 8. Auditing & guardrails (advanced)

- **CloudTrail** — logs every API call made in the account (who, what, when, from where) —
  the audit trail for "who did this."
- **IAM Access Analyzer** — finds resources (S3 buckets, IAM roles, KMS keys...) shared with
  external principals, and can generate a least-privilege policy from a role's *actual* CloudTrail
  usage — the practical way to tighten an over-broad policy without guessing.
- **Credential reports / last-accessed data** — IAM can show you when a user/role's credentials or
  a specific permission were last actually used, the basis for safely removing unused access.
- **MFA** — enforce it at minimum for the root user and any human console access; increasingly
  enforced via SCP/condition keys (`aws:MultiFactorAuthPresent`) for sensitive actions.

---

## 9. Least privilege, in practice (the theme across all of this)

- Start from **zero** access and add exactly what's needed, not from `AdministratorAccess` and
  narrow later (in practice, "narrow later" rarely happens).
- Scope `Resource` to specific ARNs, not `*`, whenever the API supports it.
- Prefer **roles over long-lived users** for anything automated.
- Use **Access Analyzer** to validate a policy is no broader than what's actually used.
- Treat a policy granting `iam:*` or `sts:AssumeRole` on `*` as equivalent to full admin — it lets
  the holder create a new admin identity for themselves.

---

## Quick reference — AWS CLI

```bash
aws sts get-caller-identity                                  # who am I, right now?
aws iam list-attached-role-policies --role-name my-role
aws iam get-role --role-name my-role
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/my-role \
  --action-names s3:GetObject                                 # "would this be allowed?"
aws accessanalyzer list-findings --analyzer-arn <arn>          # external-access findings
```
