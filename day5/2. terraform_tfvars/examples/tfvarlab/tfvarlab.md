# tfvarlab — See the Whole `.tfvars` Precedence Chain in One Place

One small module, three files present at once (`terraform.tfvars`, `network.auto.tfvars`,
`tags.auto.tfvars`), zero flags needed. No resources created — safe to `apply` immediately,
nothing to destroy afterward.

---

## What's in this folder

| File | Sets | Stage |
|------|------|-------|
| `variables.tf` | `region` (default `eu-central-1`), `vpc_cidr` (default `10.0.0.0/16`), `owner_tag` (default `nobody`), `cost_center` (default `unassigned`) | Loses to everything |
| `terraform.tfvars` | `region = "us-east-1"` | Stage 1 |
| `network.auto.tfvars` | `region = "ap-south-1"`, `vpc_cidr = "172.16.0.0/16"`, `cost_center = "CC-NETWORK"` | Stage 2 (runs after Stage 1) |
| `tags.auto.tfvars` | `owner_tag = "platform-team"`, `cost_center = "CC-TAGS"` | Stage 2 (a SEPARATE file, same stage) |

Notice `cost_center` is set in **both** `.auto.tfvars` files — that's on purpose, see Step 5.

---

## Step 1 — Run it as-is, no flags at all

```bash
cd "day5/2. terraform_tfvars/examples/tfvarlab"
terraform init
terraform plan
```

Expect:
```
region_in_use      = "ap-south-1"       # network.auto.tfvars beat terraform.tfvars
vpc_cidr_in_use    = "172.16.0.0/16"    # only network.auto.tfvars set this
owner_tag_in_use   = "platform-team"    # a DIFFERENT file, loaded together with network.auto.tfvars
cost_center_in_use = "CC-TAGS"          # tags.auto.tfvars beat network.auto.tfvars — see Step 5
```

**Why `region_in_use` isn't `us-east-1` or `eu-central-1`:** three things wanted to set `region` —
the `default` (`eu-central-1`), `terraform.tfvars` (`us-east-1`), and `network.auto.tfvars`
(`ap-south-1`). Terraform resolves them in two stages: Stage 1 loads `terraform.tfvars` first
(beating the default), then Stage 2 loads every `*.auto.tfvars` file, which **always** runs after
Stage 1 is done — so `network.auto.tfvars`'s value is the last one written, and wins.

---

## Step 2 — Remove `network.auto.tfvars`'s hold on `region`, see it fall back

Comment out (or delete) just the `region = "ap-south-1"` line in `network.auto.tfvars`, keeping
`vpc_cidr` there. Then:
```bash
terraform plan
```
Now `region_in_use` becomes `"us-east-1"` — with nothing in Stage 2 fighting for `region`
anymore, Stage 1's `terraform.tfvars` value survives all the way through. `vpc_cidr_in_use` is
unaffected (still `172.16.0.0/16`) — proof each variable resolves completely independently of the
others. Put the line back before continuing.

---

## Step 3 — Delete `terraform.tfvars` entirely, see `network.auto.tfvars` win anyway

```bash
mv terraform.tfvars terraform.tfvars.disabled
terraform plan
```
`region_in_use` is **still** `"ap-south-1"` — proof that `*.auto.tfvars` doesn't need
`terraform.tfvars` to exist at all in order to win; it just always wins *if* there's a conflict.
Restore the file before continuing:
```bash
mv terraform.tfvars.disabled terraform.tfvars
```

---

## Step 4 — Delete `tags.auto.tfvars`, see `owner_tag` fall all the way back to its default

```bash
mv tags.auto.tfvars tags.auto.tfvars.disabled
terraform plan
```
`owner_tag_in_use` becomes `"nobody"` (the `default` in `variables.tf`) — with the one file that
set it gone, and no `-var`/`-var-file` supplying it either, there's nothing left but the default.
Restore it:
```bash
mv tags.auto.tfvars.disabled tags.auto.tfvars
```

---

## Step 5 — When TWO `.auto.tfvars` files fight over the SAME variable

`cost_center` is set in **both** `network.auto.tfvars` (`"CC-NETWORK"`) and `tags.auto.tfvars`
(`"CC-TAGS"`) — a realistic accident (two people editing separate files, neither aware the other
already set this). Unlike `region` in Steps 1-3, this isn't a Stage 1 vs. Stage 2 fight — **both
of these are Stage 2.** So how does Terraform decide?

```bash
terraform plan
```
```
cost_center_in_use = "CC-TAGS"
```

**Purely by filename, alphabetically:** within Stage 2, Terraform processes every `*.auto.tfvars`
file in alphabetical order, and the *last* one processed wins if there's a conflict.
`"network.auto.tfvars"` sorts before `"tags.auto.tfvars"` (`n` comes before `t`), so
`tags.auto.tfvars` loads second and its value survives.

**Prove it by renaming, not editing.** Rename `network.auto.tfvars` to something that sorts
*after* `tags.auto.tfvars` alphabetically:
```bash
mv network.auto.tfvars zzz_network.auto.tfvars
terraform plan
```
```
cost_center_in_use = "CC-NETWORK"
```
Same two values, same two files, **zero content changed** — only the filename — and the winner
flipped. That's proof this tie-break is genuinely alphabetical-by-filename, nothing else. Rename
it back before continuing:
```bash
mv zzz_network.auto.tfvars network.auto.tfvars
```

---

## The whole lesson, in two sentences

**Across stages:** Stage 1 (`terraform.tfvars` → `terraform.tfvars.json`) always finishes loading
completely before Stage 2 (`*.auto.tfvars` → `*.auto.tfvars.json`) even starts — so any variable
set in both stages is decided entirely by Stage 2, regardless of what any file involved happens
to be named (Steps 1-3).

**Within Stage 2:** if two `*.auto.tfvars` files both set the same variable, the tie is broken
purely by **alphabetical filename order** — whichever one sorts last wins, which is why renaming
a file (with zero content change) can flip the result (Step 5).
