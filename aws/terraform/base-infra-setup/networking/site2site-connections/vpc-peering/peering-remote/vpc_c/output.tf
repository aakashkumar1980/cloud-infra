output "output-securitygroup-vpc_left2right" {
  value = module.SECURITYGROUP-CREATE.output-securitygroup-vpc_left2right
}
output "output-securitygroup-vpc_center2right" {
  value = module.SECURITYGROUP-CREATE.output-securitygroup-vpc_center2right
}

output "output-nacl_ingress_rule-vpc_left2right" {
  value = module.NACL-UPDATE.output-nacl_ingress_rule-vpc_left2right
}
output "output-nacl_ingress_rule-vpc_center2right" {
  value = module.NACL-UPDATE.output-nacl_ingress_rule-vpc_center2right
}