output "output-sg" {
  value = module.SECURITYGROUP.output-sg
}

output "output-nacl_ingress_rule" {
  value = module.NACL-INGRESS[*].output-nacl_ingress_rule
}