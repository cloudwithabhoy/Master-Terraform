data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  # join(): build a name out of pieces, joined by "-".
  instance_name = join("-", ["payment", var.environment, "01"])

  # coalesce(): Think of it as a chain of fallbacks: "try this, if it's null
  #  try the next thing, if that's null too, try the next..."
  # Here it's given two arguments:
  #  1. var.instance_name_override — tried first
  #  2. upper(local.instance_name) — the fallback
  final_name = coalesce(var.instance_name_override, upper(local.instance_name))

  #  If someone ran -var="environment=staging" instead:
  #  - lookup() searches for the key "staging"
  #  - Not found in the map (only dev/qa/prod exist)
  #  - Falls back to the third argument → returns "t3.micro"
  #  - instance_type becomes "t3.micro" instead of erasing/crashing
  instance_type = lookup(var.instance_types, var.environment, "t3.micro")

  # merge(): layer project-wide default tags with any caller-supplied extras
  # into one map — later maps win if a key repeats.
  common_tags = merge(
    { ManagedBy = "terraform", Project = "payment" },
    var.extra_tags
  )
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type

  tags = merge(local.common_tags, {
    Name        = local.final_name
    Environment = upper(var.environment)
  })
}
