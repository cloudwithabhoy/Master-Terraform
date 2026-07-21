# --- Confirms one ingress rule was generated per entry in var.ingress_rules -
output "ingress_ports" {
  value = [for rule in aws_security_group.web.ingress : rule.from_port]
}

# Try: terraform apply — 3 ingress rules appear (80, 443, 22), one per entry
# in var.ingress_rules. Add a 4th entry to the list and re-plan: a 4th
# ingress {} block appears with zero changes to hand-write.
