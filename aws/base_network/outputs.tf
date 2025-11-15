/**
 * Outputs the IDs of the created VPCs and subnets, internet_gateways for us-east-1 (N. Virginia).
 */
output "nvirginia_vpc_ids" {
  value = module.networking_nvirginia.vpc_ids
}
output "nvirginia_subnet_ids" {
  value = module.networking_nvirginia.subnet_ids
}
output "nvirginia_igw_ids" {
  value = module.networking_nvirginia.igw_ids
}
output "nvirginia_route_table_public_ids" {
  value = module.networking_nvirginia.route_table_public_ids
}

/**
 * Outputs the IDs of the created VPCs and subnets, internet_gateways for eu-west-2 (London).
 */
output "london_vpc_ids" {
  value = module.networking_london.vpc_ids
}
output "london_subnet_ids" {
  value = module.networking_london.subnet_ids
}
output "london_igw_ids" {
  value = module.networking_london.igw_ids
}
output "london_route_table_public_ids" {
  value = module.networking_london.route_table_public_ids
}
