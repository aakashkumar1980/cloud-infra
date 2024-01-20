output "output_peering_remote_requester_vpc_a2c" {
  value = module.PEERING-VPC_A2C.output-vpc_peering_connection-request
}
output "output_peering_remote_requester_vpc_b2c" {
  value = module.PEERING-VPC_B2C.output-vpc_peering_connection-request
}

output "output_peering_remote_accepter_vpc_c2a" {
  value = module.PEERING-VPC_C2A.output-vpc_peering_connection-accept
}
output "output_peering_remote_accepter_vpc_c2b" {
  value = module.PEERING-VPC_C2B.output-vpc_peering_connection-accept
}

