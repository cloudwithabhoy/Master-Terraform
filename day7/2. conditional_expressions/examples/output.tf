# --- Shows which branch of each conditional VALUE actually got picked -------
output "web_instance_type" {
  value = aws_instance.web.instance_type
}

output "web_backup_tag" {
  value = aws_instance.web.tags["Backup"]
}

# Try: terraform apply with the default (environment = "dev") — outputs read
# "t3.micro" and "Disabled". Then:
#   terraform apply -var="environment=prod"
# — the instance is destroyed and recreated as "t3.large" (instance_type is a
# ForceNew attribute) with Backup = "Enabled", and both outputs change to match.
