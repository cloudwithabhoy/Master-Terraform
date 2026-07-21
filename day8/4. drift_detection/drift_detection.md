# Day 8, Topic 4 — Drift Detection

**Goal:** Understand what "drift" is, how `terraform plan` already detects it every time you run
it, and the specific `-refresh-only` workflow for inspecting (and optionally accepting) drift
without immediately trying to revert it.

**Prerequisites:** [Topic 3 — `terraform import`](../3.%20terraform_import/terraform_import.md)
read first.

---

## 1. What "drift" means

**Drift** is any difference between what your Terraform code says should exist and what actually
exists in AWS right now — caused by someone (or something) changing a Terraform-managed resource
outside of Terraform: a manual console edit, a different CI pipeline, another engineer's `aws`
CLI command, even an AWS-initiated change in rare cases.

---

## 2. `terraform plan` already detects drift, every time

Every `plan` you've run since Day 3 has done two things: **refreshed** its understanding of real
resources (an API call per resource), then compared that against your code. If reality had
drifted, that's exactly what showed up as an unexpected `~` (update) or `-/+` (replace) in the
plan you weren't expecting — you've likely already seen drift in this course without naming it as
such.

---

## 3. `-refresh-only`: inspect drift without proposing a fix

```bash
terraform plan -refresh-only
```

Refreshes state from real infrastructure and shows you **exactly what changed**, but proposes
**no corrective action** — it doesn't suggest reverting the drift back to match your code, or
updating your code to match reality. It's purely observational: "here's what's different,
decide what to do about it yourself."

Contrast with an ordinary `terraform plan`, which — if it detects the same drift — would propose
changing the resource back to match your `.tf` code (or replacing it, depending on what changed).

---

## 4. Two ways to resolve drift, once you've seen it

| Approach | Command | When |
|----------|---------|------|
| **Accept the drift into state** (stop fighting it) | `terraform apply -refresh-only` | The manual change was intentional/correct, and your **code** should be updated to match (do that too, separately) |
| **Revert the drift** (enforce your code) | ordinary `terraform apply` | The manual change was a mistake, or unauthorized, and the code is the source of truth |

`terraform apply -refresh-only` updates **state only** — it does not touch real infrastructure at
all. It's the deliberate way of saying "I acknowledge reality changed; stop showing me this as a
pending fix" — but it does **not** update your `.tf` code to match, which you should still do by
hand afterward if you intend to keep the drifted value going forward (otherwise the next person
to run a normal `plan`/`apply` will revert it again).

### The nuance worth being precise about: `-refresh-only` doesn't "accept" drift by itself

Every ordinary `plan`/`apply` **already** refreshes state automatically, every time, by default —
that part isn't special to `-refresh-only`. What's actually different is that an ordinary `apply`
*couples* that refresh together with *fixing* whatever it finds. `-refresh-only` *decouples*
those two things: it updates state to match reality, then stops — it never fixes anything.

Because of that: running `terraform apply -refresh-only` does **not**, by itself, stop the *next*
ordinary `plan` from proposing to revert the same drift again. Your code still says what it said
before — state now matches reality, but reality still doesn't match code. Nothing about
`-refresh-only` is permanent until you also update the code yourself.

So if it doesn't fix anything, why use it at all? Two real reasons:

1. **Safety in automation.** A real team commonly runs `terraform plan -refresh-only` on a
   schedule (a nightly CI job) purely to detect and *alert* on drift (Slack, email, whatever).
   That job must never be able to accidentally revert real infrastructure just by running —
   `-refresh-only` guarantees it can't, no matter what it finds.
2. **Reviewing before deciding, on a state file with many resources.** If your state has 20
   resources and only one drifted, an ordinary `apply` right now might *also* apply other
   unrelated pending code changes you weren't ready to ship yet — refresh and "apply my real
   changes" are bundled together in an ordinary apply. `-refresh-only` lets you sync just the
   drifted state cleanly, as its own deliberate checkpoint, without touching anything else in
   the plan.

The full "truly keep this drift permanently" workflow is always two separate steps:
```bash
terraform apply -refresh-only   # 1. sync state, no revert — just a safe checkpoint
# 2. THEN go update main.tf's tags (or whatever drifted) to match, by hand
terraform apply                 # 3. now code = state = reality; "No changes" forever after
```

---

## 5. Common causes of drift, ranked by how often they actually happen

1. **A manual console "quick fix"** during an incident, never followed up with a matching code
   change — the single most common cause.
2. **A second automation tool** (a different CI job, a Lambda, a script) touching the same
   resource Terraform manages.
3. **`ignore_changes` masking real drift on purpose** (Day 7 Topic 4) — a deliberate trade-off,
   not accidental drift, but worth remembering it's there when investigating "why didn't `plan`
   catch this?"
4. **AWS itself changing something** (rare) — e.g. an AWS-managed default changing between
   provider versions, surfacing as an unexpected diff after an upgrade (Day 4 Topic 1's safe
   upgrade loop exists partly to catch this early).

---

## 6. Drift detection as an ongoing practice, not a one-off

A real team runs `terraform plan` (or `-refresh-only` specifically) **on a schedule** (e.g. a
nightly CI job) against every managed environment, alerting on any unexpected diff — catching
drift within hours instead of discovering it by accident months later when it causes a confusing
`apply` failure.

---

## Small illustrative snippet

Drift only means something against a *real*, already-applied resource — see
[`examples/main.tf`](./examples/main.tf) for a small, free S3 bucket to cause and observe drift
on yourself, and [`examples/how_to_run.md`](./examples/how_to_run.md) for the full step-by-step
walkthrough: create it from code, manually change it (simulating the console), detect the drift
with `-refresh-only`, then resolve it either way (§4).

---

## Checklist
- [ ] I can explain what drift is in one sentence
- [ ] I can explain the difference between `-refresh-only`'s plan and an ordinary plan
- [ ] I can explain when `apply -refresh-only` is the right call vs. an ordinary `apply`
- [ ] I can explain why `apply -refresh-only` alone does NOT stop the next ordinary `plan` from
      proposing to revert the same drift — and what the one manual step is that actually does

This is the last topic of the concept curriculum. Next: the standalone **capstone project**
(see the repo [`README.md`](../../README.md), and [`final-project/PROJECT.md`](../../final-project/PROJECT.md)).
