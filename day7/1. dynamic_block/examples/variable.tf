variable "ingress_rules" {
  description = "One entry per ingress rule to generate — the dynamic block below creates one nested ingress {} per entry."
  type = list(object({
    port = number
    cidr = string
  }))
  default = [
    {
      port = 80
      cidr = "0.0.0.0/0"
    },
    {
      port = 443
      cidr = "0.0.0.0/0"
    },
    {
      port = 22
      cidr = "10.0.0.0/16"
    }
  ]
}
