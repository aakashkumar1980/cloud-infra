output "output-sg_nat" {
  value = { for k, v in module.NAT-INSTANCE : k => v.output-sg_nat }
}

