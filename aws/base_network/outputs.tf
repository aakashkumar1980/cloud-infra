/**
 * Outputs - Hierarchical Network Infrastructure
 *
 * Displays all networking resources organized by region and VPC
 * in a hierarchical tree structure.
 */

/**
 * N. Virginia Region (us-east-1)
 *
 * Hierarchical output showing:
 *   Region -> VPC -> Internet Gateway, Subnets -> NAT Gateway, Route Table -> Routes
 */
output "nvirginia" {
  description = "N. Virginia region network infrastructure hierarchy"
  value = {
    for vpc_key, vpc_name in module.vpc_nvirginia.vpc_names : vpc_name => {
      cidr = module.vpc_nvirginia.vpc_cidrs[vpc_key]

      internet_gateway = lookup(module.vpc_nvirginia.igw_names, vpc_key, null)

      subnets = {
        for subnet_key, subnet_name in module.vpc_nvirginia.subnet_names :
        subnet_name => {
          cidr = module.vpc_nvirginia.subnet_cidrs[subnet_key]

          nat_gateway = (
            contains(keys(module.vpc_nvirginia.public_subnet_ids), subnet_key) &&
            contains(keys(module.vpc_nvirginia.nat_gateway_names), vpc_key)
          ) ? module.vpc_nvirginia.nat_gateway_names[vpc_key] : null

          route_table = {
            name = contains(keys(module.vpc_nvirginia.route_table_public_names), subnet_key) ? module.vpc_nvirginia.route_table_public_names[subnet_key] : module.vpc_nvirginia.route_table_private_names[subnet_key]

            routes = contains(keys(module.vpc_nvirginia.route_table_public_names), subnet_key) ? concat(
              ["${module.vpc_nvirginia.vpc_cidrs[vpc_key]} -> local"],
              [
                for route in try(module.vpc_nvirginia.route_table_public_routes[module.vpc_nvirginia.route_table_public_names[subnet_key]].routes, []) :
                "${route.destination} -> ${route.target_name}"
              ]
            ) : concat(
              ["${module.vpc_nvirginia.vpc_cidrs[vpc_key]} -> local"],
              [
                for route in try(module.vpc_nvirginia.route_table_private_routes[module.vpc_nvirginia.route_table_private_names[subnet_key]].routes, []) :
                "${route.destination} -> ${route.target_name}"
              ]
            )
          }
        }
        if split("/", subnet_key)[0] == vpc_key
      }
    }
  }
}

/**
 * London Region (eu-west-2)
 *
 * Hierarchical output showing:
 *   Region -> VPC -> Internet Gateway, Subnets -> NAT Gateway, Route Table -> Routes
 */
output "london" {
  description = "London region network infrastructure hierarchy"
  value = {
    for vpc_key, vpc_name in module.vpc_london.vpc_names : vpc_name => {
      cidr = module.vpc_london.vpc_cidrs[vpc_key]

      internet_gateway = lookup(module.vpc_london.igw_names, vpc_key, null)

      subnets = {
        for subnet_key, subnet_name in module.vpc_london.subnet_names :
        subnet_name => {
          cidr = module.vpc_london.subnet_cidrs[subnet_key]

          nat_gateway = (
            contains(keys(module.vpc_london.public_subnet_ids), subnet_key) &&
            contains(keys(module.vpc_london.nat_gateway_names), vpc_key)
          ) ? module.vpc_london.nat_gateway_names[vpc_key] : null

          route_table = {
            name = contains(keys(module.vpc_london.route_table_public_names), subnet_key) ? module.vpc_london.route_table_public_names[subnet_key] : module.vpc_london.route_table_private_names[subnet_key]

            routes = contains(keys(module.vpc_london.route_table_public_names), subnet_key) ? concat(
              ["${module.vpc_london.vpc_cidrs[vpc_key]} -> local"],
              [
                for route in try(module.vpc_london.route_table_public_routes[module.vpc_london.route_table_public_names[subnet_key]].routes, []) :
                "${route.destination} -> ${route.target_name}"
              ]
            ) : concat(
              ["${module.vpc_london.vpc_cidrs[vpc_key]} -> local"],
              [
                for route in try(module.vpc_london.route_table_private_routes[module.vpc_london.route_table_private_names[subnet_key]].routes, []) :
                "${route.destination} -> ${route.target_name}"
              ]
            )
          }
        }
        if split("/", subnet_key)[0] == vpc_key
      }
    }
  }
}
