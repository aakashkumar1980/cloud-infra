output "output_peering_local_vpc_a2b" {
  value = module.LOCAL.output_peering_local_vpc_a2b
}



output "output_peering_remote_requester_vpc_a2c" {
  value = module.REMOTE.output_peering_remote_requester_vpc_a2c
}
output "output_peering_remote_requester_vpc_b2c" {
  value = module.REMOTE.output_peering_remote_requester_vpc_b2c
}

output "output_peering_remote_accepter_vpc_c2a" {
  value = module.REMOTE.output_peering_remote_accepter_vpc_c2a
}
output "output_peering_remote_accepter_vpc_c2b" {
  value = module.REMOTE.output_peering_remote_accepter_vpc_c2b
}
