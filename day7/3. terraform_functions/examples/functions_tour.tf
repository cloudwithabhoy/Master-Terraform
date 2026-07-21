# =============================================================================
# functions_tour.tf  —  Illustrative only (matches terraform_functions.md §2-6)
# -----------------------------------------------------------------------------
# No AWS resources — every output below computes purely from functions, so
# `terraform apply` here is instant and free.
# =============================================================================

terraform {
  required_version = ">= 1.5"
}

locals {
  # Deliberately missing "prod" — used below to show try() catching a real
  # "index doesn't exist" error, which is what try() is actually for (it
  # cannot catch a reference to an undeclared variable/resource — that's a
  # configuration error, not a runtime one).
  instance_types_by_env = {
    dev = "t2.micro"
    qa  = "t2.micro"
  }
}

# --- String functions (§2) ----------------------------------------------------
output "string_functions" {
  value = {
    upper_example     = upper("dev")
    join_example      = join("-", ["a", "b", "c"])
    split_example     = split("-", "a-b-c")
    format_example    = format("%s-%03d", "web", 7)
    replace_example   = replace("hello world", "world", "there")
    trimspace_example = trimspace("  hi  ")
  }
}

# --- Collection functions (§3) -------------------------------------------------
output "collection_functions" {
  value = {
    merge_example    = merge({ a = 1 }, { b = 2 })
    lookup_example    = lookup({ dev = "t2.micro" }, "prod", "t3.micro")
    keys_example       = keys({ a = 1, b = 2 })
    values_example       = values({ a = 1, b = 2 })
    concat_example         = concat([1, 2], [3])
    distinct_example         = distinct([1, 2, 2, 3])
    flatten_example           = flatten([[1, 2], [3]])
    contains_example           = contains(["dev", "qa"], "dev")
  }
}

# --- Type conversion functions (§4) -------------------------------------------
output "type_conversion_functions" {
  value = {
    tostring_example = tostring(5)
    tonumber_example = tonumber("5")
    toset_example    = toset(["a", "a", "b"])
    try_example           = try("ok", "fallback") # succeeds, so returns "ok"
    try_fallback_example  = try(local.instance_types_by_env["prod"], "fallback") # "prod" key doesn't exist -> errors -> falls back
    coalesce_example      = coalesce(null, "b", "c")
  }
}

# --- Encoding functions (§5) ---------------------------------------------------
output "encoding_functions" {
  value = {
    jsonencode_example   = jsonencode({ Effect = "Allow", Action = "s3:GetObject" })
    base64encode_example = base64encode("hello")
  }
}

# --- CIDR / numeric functions (§6) ---------------------------------------------
output "cidr_and_numeric_functions" {
  value = {
    cidrsubnet_example = cidrsubnet("10.0.0.0/16", 8, 1)
    max_example        = max(3, 7, 2)
    ceil_example       = ceil(4.2)
  }
}

# Try: terraform console
#   Paste any single expression above (without the surrounding output block)
#   to see its result immediately, without a full apply.
