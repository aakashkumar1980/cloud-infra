/**
 * Routes Module - Outputs
 */

output "vpc_a_routes" {
  value = {
    for rt_id, route in aws_route.route_vpc_a_to_vpc_b : rt_id => {
      route_table_id         = route.route_table_id
      destination_cidr_block = route.destination_cidr_block
      target                 = route.vpc_peering_connection_id
    }
  }
  description = "Routes added to vpc_a route tables"
}

output "vpc_b_routes" {
  value = {
    for rt_id, route in aws_route.route_vpc_b_to_vpc_a : rt_id => {
      route_table_id         = route.route_table_id
      destination_cidr_block = route.destination_cidr_block
      target                 = route.vpc_peering_connection_id
    }
  }
  description = "Routes added to vpc_b route tables"
}
