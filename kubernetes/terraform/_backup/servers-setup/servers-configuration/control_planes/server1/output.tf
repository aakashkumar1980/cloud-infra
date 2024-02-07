output "output-eni" {
  value = module.EC2-INSTANCE.output-eni
}
output "output-ec2" {
  value = module.EC2-INSTANCE.output-ec2
}
output "output-ec2-subnet" {
  value = module.EC2-INSTANCE.output-ec2-subnet
}

output "output-sg" {
  value = module.API_SERVER_PORT-ACCESS.output-sg
}
output "output-nacl_ingress_rule" {
  value = module.API_SERVER_PORT-ACCESS.output-nacl_ingress_rule
}