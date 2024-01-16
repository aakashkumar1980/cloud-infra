output "output-nacl_ingress_rule-vpc_left2right" {
  value = module.NACL_INGRESS-VPC_LEFT[*].output-nacl_ingress_rule
}

output "output-nacl_ingress_rule-vpc_center2right" {
  value = module.NACL_INGRESS-VPC_CENTER[*].output-nacl_ingress_rule
}