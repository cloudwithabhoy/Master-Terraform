data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

variable "environment" {
  type    = string
  default = "prod"
}

# --- Conditional VALUE (matches §3): instance_type AND the Backup tag both
# differ by environment — two independent conditional values on one resource.
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  tags = {
    Name   = "web"
    Backup = var.environment == "prod" ? "Enabled" : "Disabled"
  }
}
