output "output-peering_remote_request-vpc_right2left" {
  value = module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2LEFT.output-vpc_peering_connection-request
}
output "output-peering_remote_request-vpc_right2center" {
  value = module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2CENTER.output-vpc_peering_connection-request
}
output "output-peering_remote_request-vpc_privatelearningv2center" {
  value = module.PEERING_REMOTE_REQUESTER-VPC_PRIVATELEARNINGV2CENTER.output-vpc_peering_connection-request
}

output "output-securitygroup-vpc_left2right" {
  value = module.VPC_RIGHT.output-securitygroup-vpc_left2right
}
output "output-securitygroup-vpc_center2right" {
  value = module.VPC_RIGHT.output-securitygroup-vpc_center2right
}
output "output-nacl_ingress_rule-vpc_left2right" {
  value = module.VPC_RIGHT.output-nacl_ingress_rule-vpc_left2right
}
output "output-nacl_ingress_rule-vpc_center2right" {
  value = module.VPC_RIGHT.output-nacl_ingress_rule-vpc_center2right
}


