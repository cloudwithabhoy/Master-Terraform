# `bootstrap/dev` — run this once, before anything else in `environments/dev`

This is the **one deliberate exception** to "every apply happens through the pipeline" (see
`PROJECT.md`'s "The plan"). It creates the S3 bucket + DynamoDB table `environments/dev`'s own
backend depends on — it can't use that backend itself, since the bucket/table don't exist until
this config applies. Local state, run by hand, once, then left alone.

## Run it

```bash
cd final-project/bootstrap/dev
terraform init
terraform plan
terraform apply
```

Type `yes`. Cost: a few cents a month at most (S3 + a near-idle DynamoDB table on
pay-per-request billing) — leave it running; destroying it would delete `environments/dev`'s
state along with it.

## After applying

Confirm the outputs match `environments/dev/providers.tf`'s `backend "s3"` block **exactly**:

```bash
terraform output state_bucket_name
terraform output lock_table_name
```

If they don't match (e.g. you changed `state_bucket_name`/`lock_table_name` in `variables.tf`
without updating `environments/dev/providers.tf` to match), fix one side or the other before
running `terraform init` in `environments/dev` — a mismatch means that config's `init` will fail
to find the bucket at all.

## Do not destroy this casually

Unlike everything else in this project, **do not** run `terraform destroy` here as part of your
normal end-of-session cleanup. This bucket holds `environments/dev`'s actual state — destroying it
while `environments/dev` still has real resources means Terraform loses track of everything it
manages there. Only tear this down after `environments/dev` itself has been fully destroyed and
you're certain you're done with `dev` for good.
