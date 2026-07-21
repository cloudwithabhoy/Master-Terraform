# Day 8, Topic 2 — Terraform Functions

**Goal:** Take a guided tour of the built-in functions you'll reach for constantly — string,
collection, type-conversion, and encoding functions — and learn `terraform console` as the tool
for testing any of them before putting them in real code.

**Prerequisites:** Day 7 complete.

---

## 1. There is no way to write your own function

Unlike most languages, HCL has **no user-defined functions** — you only get Terraform's built-in
ones (plus what you can express with `for` expressions and conditionals). This is deliberate:
Terraform is declarative, not a general-purpose scripting language, and the built-in function set
covers the vast majority of real configuration needs.

---

## 2. String functions

| Function | Example | Result |
|----------|---------|--------|
| `upper(s)` / `lower(s)` | `upper("dev")` | `"DEV"` |
| `join(sep, list)` | `join("-", ["a", "b", "c"])` | `"a-b-c"` |
| `split(sep, s)` | `split("-", "a-b-c")` | `["a", "b", "c"]` |
| `format(spec, ...)` | `format("%s-%03d", "web", 7)` | `"web-007"` |
| `replace(s, old, new)` | `replace("hello world", "world", "there")` | `"hello there"` |
| `trimspace(s)` | `trimspace("  hi  ")` | `"hi"` |

You've already used `join` and string interpolation (`"${a}-${b}"`) throughout this course without
naming it as a "function" — `join`/`split` are the same idea generalized to whole lists.

---

## 3. Collection functions

| Function | Example | Result |
|----------|---------|--------|
| `merge(map1, map2, ...)` | `merge({a=1}, {b=2})` | `{a=1, b=2}` — this is `local.common_tags`'s pattern (Day 3) |
| `lookup(map, key, default)` | `lookup({dev="t2.micro"}, "prod", "t3.micro")` | `"t3.micro"` (key missing, uses default) |
| `keys(map)` / `values(map)` | `keys({a=1, b=2})` | `["a", "b"]` |
| `concat(list1, list2)` | `concat([1,2], [3])` | `[1, 2, 3]` |
| `distinct(list)` | `distinct([1, 2, 2, 3])` | `[1, 2, 3]` |
| `flatten(list_of_lists)` | `flatten([[1,2], [3]])` | `[1, 2, 3]` |
| `contains(list, value)` | `contains(["dev","qa"], "dev")` | `true` — this is what every `validation` block in this course uses |

---

## 4. Type conversion functions

| Function | Example | Result |
|----------|---------|--------|
| `tostring(v)` | `tostring(5)` | `"5"` |
| `tonumber(v)` | `tonumber("5")` | `5` |
| `tolist(v)` / `toset(v)` | `toset(["a","a","b"])` | `["a", "b"]` (a set, deduplicated) |
| `try(expr, default)` | `try(local.instance_types["prod"], "t3.micro")` | evaluates `expr`, returns `default` if it errors (e.g. the `"prod"` key doesn't exist in the map) |
| `coalesce(v1, v2, ...)` | `coalesce(null, "b", "c")` | `"b"` (first **non-null** argument — note an empty string `""` is NOT null, so it would be returned as-is, not skipped) |

`try()` is the closest thing HCL has to a "safe navigation" operator — invaluable when an
attribute might not exist yet (e.g. reading an optional block from a variable).

---

## 5. Encoding functions (you've already used two of these)

| Function | Used where in this course |
|----------|---------------------------|
| `jsonencode(value)` | Day 4's `iam_as_code.md` §1 — turning an HCL map into a JSON policy string |
| `base64encode(s)` / `base64decode(s)` | Encoding `user_data` scripts that require base64 (some resource types need this explicitly; `aws_instance.user_data` does not) |
| `templatefile(path, vars)` | Rendering a file (e.g. a `user_data` script) as a template with variables substituted in |

---

## 6. CIDR & numeric functions (already used, named properly now)

- **`cidrsubnet(prefix, newbits, netnum)`** — carves a smaller CIDR block out of a larger one
  (e.g. `cidrsubnet("10.0.0.0/16", 8, 0)` → `10.0.0.0/24`) — a Terraform **function**, not an AWS
  API call, useful anywhere you're computing network ranges programmatically.
- **`min(...)` / `max(...)` / `ceil(x)` / `floor(x)`** — ordinary numeric helpers, useful for
  computing things like "how many AZs fit" from a variable.

---

## 7. `terraform console` — test any function before using it

```bash
terraform console
> upper("dev")
"DEV"
> merge({a = 1}, {b = 2})
{
  "a" = 1
  "b" = 2
}
> exit
```

This is the fastest feedback loop for a function you're unsure about — faster than writing it into
a `.tf` file, running `plan`, and reading the error if you got the arguments wrong.

---

## Small illustrative snippet

See [`examples/functions_tour.tf`](examples/functions_tour.tf) — every function above,
wired into outputs so `terraform apply` prints all of their results at once.

For the same functions applied to a real resource instead of bare outputs, see
[`examples/main.tf`](examples/main.tf) — one small EC2 instance whose name, size, and tags are
all derived from `var.environment`:

| Function | What it does here |
|---|---|
| `join()` | Builds `"payment-prod-01"` out of pieces |
| `upper()` | Normalizes the fallback name and the `Environment` tag |
| `coalesce()` | Uses an override name if given, else falls back to the auto-generated one |
| `lookup()` | Sizes the instance by environment, with a safe default |
| `contains()` | Validates `var.environment` is one of `dev`/`qa`/`prod` |
| `merge()` | Layers project-wide default tags with any caller-supplied extras |

---

## Checklist
- [ ] I can name at least one string, one collection, and one type-conversion function from memory
- [ ] I can explain what `try()` is for
- [ ] I used `terraform console` to test a function before writing it into a `.tf` file

Next: **[Topic 3 — Lifecycle Rules](../4.%20lifecycle_rules/lifecycle_rules.md)**.
