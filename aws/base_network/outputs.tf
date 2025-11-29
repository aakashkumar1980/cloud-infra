/**
 * Outputs - N. Virginia Region (us-east-1)
 *
 * Exposes the names and routing information for all networking
 * resources created in the N. Virginia region.
 */
output "aa_nvirginia_vpc_names" {
  value = [
    for k, name in module.networking_nvirginia.vpc_names :
    "${name} (${module.networking_nvirginia.vpc_cidrs[k]})"
  ]
  description = "Names and CIDR ranges of VPCs in N. Virginia"
}
output "ab_nvirginia_igw_names" {
  value       = values(module.networking_nvirginia.igw_names)
  description = "Names of Internet Gateways in N. Virginia"
}
output "ac_nvirginia_subnet_names" {
  value = [
    for k, name in module.networking_nvirginia.subnet_names :
    "${name} (${module.networking_nvirginia.subnet_cidrs[k]})"
  ]
  description = "Names and CIDR ranges of subnets in N. Virginia"
}
output "ad_nvirginia_route_table_public_routes" {
  value       = module.networking_nvirginia.route_table_public_routes
  description = "Public route table routing info in N. Virginia"
}
output "ae_nvirginia_nat_gateway_names" {
  value       = values(module.networking_nvirginia.nat_gateway_names)
  description = "Names of NAT Gateways in N. Virginia"
}
output "af_nvirginia_route_table_private_routes" {
  value       = module.networking_nvirginia.route_table_private_routes
  description = "Private route table routing info in N. Virginia"
}

/**
 * Outputs - London Region (eu-west-2)
 *
 * Exposes the names and routing information for all networking
 * resources created in the London region.
 */
output "ba_london_vpc_names" {
  value = [
    for k, name in module.networking_london.vpc_names :
    "${name} (${module.networking_london.vpc_cidrs[k]})"
  ]
  description = "Names and CIDR ranges of VPCs in London"
}
output "bb_london_igw_names" {
  value       = values(module.networking_london.igw_names)
  description = "Names of Internet Gateways in London"
}
output "bc_london_subnet_names" {
  value = [
    for k, name in module.networking_london.subnet_names :
    "${name} (${module.networking_london.subnet_cidrs[k]})"
  ]
  description = "Names and CIDR ranges of subnets in London"
}
output "bd_london_route_table_public_routes" {
  value       = module.networking_london.route_table_public_routes
  description = "Public route table routing info in London"
}
output "be_london_nat_gateway_names" {
  value       = values(module.networking_london.nat_gateway_names)
  description = "Names of NAT Gateways in London"
}
output "bf_london_route_table_private_routes" {
  value       = module.networking_london.route_table_private_routes
  description = "Private route table routing info in London"
}
