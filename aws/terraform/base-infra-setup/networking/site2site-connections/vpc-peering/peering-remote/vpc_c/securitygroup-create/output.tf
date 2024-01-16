output "output-securitygroup-vpc_left2right" {
  value = merge(module.SECURITYGROUP-VPC_LEFT.output-sg, {"network_interface_id"=var.eni_id})
}

output "output-securitygroup-vpc_center2right" {
  value = merge(module.SECURITYGROUP-VPC_CENTER.output-sg, {"network_interface_id"=var.eni_id})
}