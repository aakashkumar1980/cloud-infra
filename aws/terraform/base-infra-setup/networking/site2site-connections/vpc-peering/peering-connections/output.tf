output "output_peering_local-vpc_a2b" {
  value = module.LOCAL.output_peering_local-vpc_a2b
}



output "output_peering_remote_requester-vpc_a2c" {
  value = module.REMOTE.output_peering_remote_requester-vpc_a2c
}
output "output_peering_remote_requester-vpc_b2c" {
  value = module.REMOTE.output_peering_remote_requester-vpc_b2c
}

output "output_peering_remote_accepter-vpc_c2a" {
  value = module.REMOTE.output_peering_remote_accepter-vpc_c2a
}
output "output_peering_remote_accepter-vpc_c2b" {
  value = module.REMOTE.output_peering_remote_accepter-vpc_c2b
}
