# --- One "ingress" nested block generated per entry in var.ingress_rules ----
resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port = ingress.value.port
      to_port   = ingress.value.port
      protocol  = "tcp"

      cidr_blocks = [
        ingress.value.cidr
      ]
    }
  }
}
