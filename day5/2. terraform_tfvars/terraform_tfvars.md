# Day 5, Topic 2 — `terraform.tfvars`

**Goal:** Go from typing `-var` flags by hand (every lab so far) to real `.tfvars` files — the
actual mechanism a team uses to run the same code against `dev`/`qa`/`prod` without editing `.tf`
files or retyping flags.

**Prerequisites:** [Topic 1 — Project Structure](../1.%20project_structure/project_structure.md)
read first.

---

## 1. Recap: where variable values come from, precisely

Day 3 Topic 1 listed the full precedence order. Today is about the file-based options in the
middle of that list — and the one detail that trips people up: **the "automatically loaded"
files are not all equal to each other.** There's an exact order among them, and it decides who
wins when more than one sets the same variable.

| Source | Loaded how | Precedence among the automatic files |
|---|---|---|
| `terraform.tfvars` | **Automatically**, if present | Loaded **first** |
| `terraform.tfvars.json` | **Automatically**, JSON syntax instead of HCL | Loaded **second** — overrides `terraform.tfvars` if both set the same variable |
| `*.auto.tfvars` / `*.auto.tfvars.json` | **Automatically**, any filename matching this pattern, processed in alphabetical order | Loaded **last** — overrides *both* rows above if there's a conflict |
| A named file, e.g. `dev.tfvars` | **Only** if passed explicitly with `-var-file="dev.tfvars"` | Not part of the automatic group at all — it's a separate, higher-precedence mechanism |

**The part that actually surprises people:** `*.auto.tfvars` isn't just "another way to
auto-load" — it's *layered on top of* `terraform.tfvars`. If `terraform.tfvars` sets
`region = "us-east-1"` and a file called `network.auto.tfvars` *also* sets `region`, the
`.auto.tfvars` file wins — every time, regardless of what it's named — because that whole
category loads after `terraform.tfvars`/`terraform.tfvars.json` are already done.

**None of this applies to named files like `dev.tfvars`.** That row isn't "lower precedence
automatic loading" — it's not automatic at all. Terraform will never open a file called
`dev.tfvars` on its own; it only exists in your config's resolved values if you explicitly pass
`-var-file="dev.tfvars"`. This is exactly why multi-environment setups name files `dev.tfvars`,
`qa.tfvars`, `prod.tfvars` (never `terraform.tfvars`, which would apply to *every* run whether you
wanted it to or not) — the whole point is choosing exactly one, per run, on purpose.

**See it proven directly, not just asserted** —
[`examples/tfvarlab/`](./examples/tfvarlab/) puts `terraform.tfvars` and two separate
`*.auto.tfvars` files in one folder together, with a walkthrough
([`tfvarlab.md`](./examples/tfvarlab/tfvarlab.md)) that has you delete each one in turn and watch
exactly which value wins at every step.

---

## 2. The syntax

A `.tfvars` file is just variable assignments — no `variable` block, no `resource`, nothing else:

```hcl
# dev.tfvars
environment     = "dev"
project_prefix  = "master-terraform-day05"
owner_tag       = "your-name-here"
```

Run it with:
```bash
terraform plan -var-file="dev.tfvars"
```

Every `variable` block still needs to exist in your `.tf` code (with its `type`/`validation`/
`description`) — the `.tfvars` file only supplies *values*, it doesn't declare new variables.

---

## 3. The `.tfvars.example` pattern (this repo uses it today)

This repo's `.gitignore` blocks `*.tfvars` but explicitly allows `*.tfvars.example`:

```gitignore
*.tfvars
*.tfvars.json
!*.tfvars.example
```

The workflow:
1. Commit `dev.tfvars.example` (safe placeholder values, no real secrets) to git.
2. Each person/environment copies it: `cp dev.tfvars.example dev.tfvars`, then fills in anything
   real (which stays local, gitignored, never committed).
3. `-var-file="dev.tfvars"` picks up the real, local file.

This is the general pattern most real teams use for per-environment secrets/config. Day 5's own
lab keeps its `dev.tfvars`/`qa.tfvars` as real, gitignored files directly (no `.example` template
this time) — read [`lab/lab.md`](../lab/lab.md) for how that's handled here.

---

## 4. Combining `.tfvars` with `validation`

Nothing changes about `validation` blocks (Day 3 Topic 1) when values come from a file instead of
`-var` — Terraform validates *after* resolving the value regardless of its source. A `dev.tfvars`
with a typo'd `environment = "developement"` fails the exact same `validation` block, at the exact
same point (before touching AWS), as typing it wrong on the command line.

---

## 5. Common mistakes

- **Naming a per-environment file `terraform.tfvars`** — it gets loaded on *every* `plan`/`apply`
  automatically, including ones meant for a different environment. Reserve that exact filename
  for values that should truly always apply, or avoid it entirely in a multi-environment setup.
- **Committing a real `.tfvars` with secrets** — the #1 reason this repo's `.gitignore` blocks
  `*.tfvars` by default.
- **Forgetting `-var-file`** — if you name environment files `dev.tfvars`/`qa.tfvars` (not
  `*.auto.tfvars`), Terraform won't load them unless you pass the flag; a `plan` with no flag
  silently falls back to only variable `default`s.
- **Assuming `terraform.tfvars` always has the final say** — it doesn't. Both
  `terraform.tfvars.json` and any `*.auto.tfvars` file load *after* it and will silently override
  it if they set the same variable (§1). If a value looks "wrong" and you're certain
  `terraform.tfvars` is correct, check for a stray `*.auto.tfvars` file sitting in the same folder
  before assuming something else is broken.

---

## Small illustrative snippet

See [`examples/env_tfvars_pattern.md`](./examples/env_tfvars_pattern.md) for a side-by-side of
all three mechanisms, each with a real-world analogy — then the three runnable folders linked in
§1 for proof, not just explanation.

---

## Checklist
- [ ] I can explain the difference between `terraform.tfvars` (auto-loaded always) and a named
      file like `dev.tfvars` (loaded only with `-var-file`)
- [ ] I can state the exact precedence order among `terraform.tfvars`, `terraform.tfvars.json`,
      and `*.auto.tfvars` — and say which one wins if two of them set the same variable
- [ ] I can explain the `.tfvars.example` pattern and why this repo's `.gitignore` is shaped
      around it
- [ ] I understand `validation` blocks fire regardless of where the value came from

Next: today's **[shared lab](../lab/lab.md)** — one VPC module, deployed to `dev` and `qa`,
driven by `.tfvars` per environment.
