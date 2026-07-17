# Illustrative — which `.tfvars` mechanism to use, and when

Three mechanisms, three different "who gets this value, and when" answers. Each has a matching
real-world analogy below — use whichever sticks better.

---

## 1. `terraform.tfvars` — auto-loaded, always, no flag

```hcl
# terraform.tfvars
region = "us-east-1"
```

**Analogy: the company-wide employee handbook.** Every single employee gets the same handbook,
no matter which department, team, or office they belong to — there's no version for "just
marketing" or "just the Tokyo office." One document, applies to everyone, always.

**A JSON variant exists too: `terraform.tfvars.json`.**
```json
{
  "region": "us-east-1"
}
```
Same auto-loading, just JSON syntax instead of HCL — useful when something *generates* your
tfvars programmatically (a CI pipeline, a script) rather than a human hand-writing them, since
JSON is trivial to produce from code. **If both files exist, `terraform.tfvars.json` is
documented to load *after* `terraform.tfvars`, so its value wins.**

**Use for:** a value that's *truly* constant no matter who runs this config or which environment
it targets — e.g. the AWS region every environment deploys into, if that never changes. Rare in a
multi-environment setup, since most values *do* need to differ somewhere.

See [`tfvarlab/`](./tfvarlab/) (and its walkthrough, [`tfvarlab.md`](./tfvarlab/tfvarlab.md)) for
a small, runnable version of this — `terraform.tfvars` sets `region`, and so does
`network.auto.tfvars` (mechanism #2, below); run `terraform plan` with **zero flags** and watch
the `.auto.tfvars` value win, live.

---

## 2. `*.auto.tfvars` — auto-loaded, always, no flag, but split into named files

```hcl
# network.auto.tfvars
vpc_cidr = "10.0.0.0/16"

# tags.auto.tfvars
owner_tag = "platform-team"
```

**Analogy: labeled folders on a shared shelf.** Everyone walking past the shelf sees *every*
folder on it — you can't grab just the "network" folder and skip "tags." They're organized into
separate, clearly labeled files purely for human readability (so one giant `terraform.tfvars`
doesn't become an unreadable wall of unrelated settings) — but all of them load together, every
time, with zero say in the matter.

**Use for:** splitting always-loaded values into logically named files once a single
`terraform.tfvars` would get too long or mix unrelated concerns. Still **no way** to say "just
load the network one this time" — that's not what this mechanism is for (see #3).

See [`tfvarlab/`](./tfvarlab/) — `network.auto.tfvars` and `tags.auto.tfvars` sit side by side,
each overriding a different variable's default. Run `terraform plan` with **zero flags** and
**both** take effect together, proving there's no way to load just one of them. The walkthrough
in [`tfvarlab.md`](./tfvarlab/tfvarlab.md) has you delete each one in turn to see exactly what
each contributes.

---

## 3. Named file + `-var-file` — loaded ONLY when you explicitly say so

```hcl
# dev.tfvars
environment    = "dev"
instance_count = 1

# prod.tfvars
environment    = "prod"
instance_count = 3
```
```bash
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="prod.tfvars"
```

**Analogy: a restaurant handing you a specific menu because you asked for it.** The breakfast
menu doesn't show up at your dinner table by accident — you (or the waiter, on your behalf)
deliberately request the one that matches your occasion. Nothing loads unless someone explicitly
asks for that exact file, by name.

**Use for:** **any value that differs by environment** — this is the pattern Day 5's lab uses
(`environment`, `vpc_cidr` differ between `dev.tfvars` and `qa.tfvars`), and the pattern you'll
extend into the capstone's `dev`/`qa`/`prod` split.

You've already run this one for real — Day 5's own [shared lab](../../lab/lab.md) uses exactly
this mechanism: `environments/dev.tfvars` and `environments/qa.tfvars`, only loaded via explicit
`-var-file`, never automatically.

---

## Rule of thumb, all three side by side

| Mechanism | Loads when? | Analogy | Use for |
|---|---|---|---|
| `terraform.tfvars` | Always, automatically | The company handbook — everyone gets it | A value that's identical for literally everyone, always |
| `*.auto.tfvars` | Always, automatically (just split into files) | Labeled folders on a shelf — all visible, none optional | Always-loaded values, organized for readability |
| Named file + `-var-file` | Only when you pass the flag | A menu handed to you because you asked for it | Anything that differs by environment (`dev` vs. `qa` vs. `prod`) |

If the same value is correct for `dev`, `qa`, **and** `prod` → `*.auto.tfvars` (or plain
`terraform.tfvars` if there's only one such value).
If it varies by environment → a named file + explicit `-var-file`, always.
