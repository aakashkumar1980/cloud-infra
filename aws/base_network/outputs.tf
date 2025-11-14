/**
output "nvirginia_vpc_ids" {
  value = module.networking_nvirginia.vpc_ids
}
output "nvirginia_subnet_ids" {
  value = module.networking_nvirginia.subnet_ids
}

output "london_vpc_ids" {
  value = module.networking_london.vpc_ids
}
output "london_subnet_ids" {
  value = module.networking_london.subnet_ids
}
**/

output "debug" {
  value = {
    nvirginia = module.networking_nvirginia.debug,
    london    = module.networking_london.debug,
  }
}