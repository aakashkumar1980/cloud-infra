output "output-peering_local-vpc_center2left" {
  value = module.PEERING-LOCAL.output-peering_local-vpc_center2left
}
output "output-peering_remote_accept-vpc_left2right" {
  value = module.PEERING-LOCAL.output-peering_remote_accept-vpc_left2right
}
output "output-peering_remote_accept-vpc_center2right" {
  value = module.PEERING-LOCAL.output-peering_remote_accept-vpc_center2right
}
output "output-peering_remote_request-vpc_right2left" {
  value = module.PEERING-REMOTE.output-peering_remote_request-vpc_right2left
}
output "output-peering_remote_request-vpc_right2center" {
  value = module.PEERING-REMOTE.output-peering_remote_request-vpc_right2center
}
output "output-peering_remote_request-vpc_privatelearningv2center" {
  value = module.PEERING-REMOTE.output-peering_remote_request-vpc_privatelearningv2center
}

output "output-securitygroup-vpc_left2center" {
  value = module.PEERING-LOCAL.output-securitygroup-vpc_left2center
}
output "output-securitygroup-vpc_right2center" {
  value = module.PEERING-LOCAL.output-securitygroup-vpc_right2center
}
output "output-securitygroup-vpc_center2left" {
  value = module.PEERING-LOCAL.output-securitygroup-vpc_center2left
}
output "output-securitygroup-vpc_right2left" {
  value = module.PEERING-LOCAL.output-securitygroup-vpc_right2left
}
output "output-securitygroup-vpc_left2right" {
  value = module.PEERING-REMOTE.output-securitygroup-vpc_left2right
}
output "output-securitygroup-vpc_center2right" {
  value = module.PEERING-REMOTE.output-securitygroup-vpc_center2right
}

output "output-nacl_ingress_rule-vpc_left2center" {
  value = module.PEERING-LOCAL.output-nacl_ingress_rule-vpc_left2center
}
output "output-nacl_ingress_rule-vpc_right2center" {
  value = module.PEERING-LOCAL.output-nacl_ingress_rule-vpc_right2center
}
output "output-nacl_ingress_rule-vpc_center2left" {
  value = module.PEERING-LOCAL.output-nacl_ingress_rule-vpc_center2left
}
output "output-nacl_ingress_rule-vpc_right2left" {
  value = module.PEERING-LOCAL.output-nacl_ingress_rule-vpc_right2left
}
output "output-nacl_ingress_rule-vpc_left2right" {
  value = module.PEERING-REMOTE.output-nacl_ingress_rule-vpc_left2right
}
output "output-nacl_ingress_rule-vpc_center2right" {
  value = module.PEERING-REMOTE.output-nacl_ingress_rule-vpc_center2right
}



