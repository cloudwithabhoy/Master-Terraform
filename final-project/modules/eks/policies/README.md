# AWS Load Balancer Controller IAM policy

`alb_controller_iam_policy.json` in this folder is AWS's own published IAM policy for the
`aws-load-balancer-controller` project, vendored as a static file rather than hand-typed inline —
it's long, specific, and maintained upstream, not something this course is teaching character by
character.

**Before applying against a real AWS account, re-fetch the current version from the authoritative
source** and diff it against what's here — AWS periodically updates this policy as the controller
gains features, and an out-of-date copy can be either too narrow (the controller fails with
`AccessDenied`) or unnecessarily broad:

```bash
curl -o modules/eks/policies/alb_controller_iam_policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

Referenced from `modules/eks/main.tf` via:
```hcl
resource "aws_iam_policy" "alb_controller" {
  name   = "${var.name_prefix}-alb-controller-policy"
  policy = file("${path.module}/policies/alb_controller_iam_policy.json")
}
```
