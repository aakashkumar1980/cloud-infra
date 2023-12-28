output "output-sg_nat" {
  value = { for k, v in module.NAT-INSTANCE : k => v.output-sg_nat }
}

output "output-ec2_nat" {
  value = { for k, v in module.NAT-INSTANCE : k => v.output-ec2_nat }
}
