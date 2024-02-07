output "output-server1-eni" {
  value = module.SERVER1.output-eni
}
output "output-server1-ec2" {
  value = module.SERVER1.output-ec2
}
output "output-server1-ec2-subnet" {
  value = module.SERVER1.output-ec2-subnet
}

output "output-server1-sg" {
  value = module.SERVER1.output-sg
}
output "output-server1-nacl_ingress_rule" {
  value = module.SERVER1.output-nacl_ingress_rule
}
