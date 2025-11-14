/**
output "vpc_ids" {
  value = module.vpc.vpc_ids
}

output "subnet_ids" {
  value = module.subnets.subnet_ids
}
**/

output "debug" {
  value = module.subnets.debug
}
