/**
 * Outputs the IDs of the created VPCs and subnets, internet_gateways for us-east-1 (N. Virginia).
 */
output "aa_nvirginia_vpc_names" {
  value = values(module.networking_nvirginia.vpc_names)
}
output "ab_nvirginia_igw_names" {
  value = values(module.networking_nvirginia.igw_names)
}
output "ac_nvirginia_subnet_names" {
  value = values(module.networking_nvirginia.subnet_names)
}
output "ad_nvirginia_route_table_public_routes" {
  value = module.networking_nvirginia.route_table_public_routes
}
output "ae_nvirginia_nat_gateway_names" {
  value = values(module.networking_nvirginia.nat_gateway_names)
}
output "af_nvirginia_route_table_private_routes" {
  value = module.networking_nvirginia.route_table_private_routes
}

/**
 * Outputs the IDs of the created VPCs and subnets, internet_gateways for eu-west-2 (London).
 */
output "ba_london_vpc_names" {
  value = values(module.networking_london.vpc_names)
}
output "bb_london_igw_names" {
  value = values(module.networking_london.igw_names)
}
output "bc_london_subnet_names" {
  value = values(module.networking_london.subnet_names)
}
output "bd_london_route_table_public_routes" {
  value = module.networking_london.route_table_public_routes
}
output "be_london_nat_gateway_names" {
  value = values(module.networking_london.nat_gateway_names)
}
output "bf_london_route_table_private_routes" {
  value = module.networking_london.route_table_private_routes
}
