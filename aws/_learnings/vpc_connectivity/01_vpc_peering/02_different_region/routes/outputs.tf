/**
 * Routes Module - Outputs (Cross-Region)
 */

output "vpc_a_routes" {
  value = {
    for rt_id, route in aws_route.route_vpc_a_to_vpc_c : rt_id => {
      route_table_id         = route.route_table_id
      destination_cidr_block = route.destination_cidr_block
      target                 = route.vpc_peering_connection_id
      region                 = "us-east-1"
    }
  }
  description = "Routes added to vpc_a route tables (N. Virginia)"
}

output "vpc_c_routes" {
  value = {
    for rt_id, route in aws_route.route_vpc_c_to_vpc_a : rt_id => {
      route_table_id         = route.route_table_id
      destination_cidr_block = route.destination_cidr_block
      target                 = route.vpc_peering_connection_id
      region                 = "eu-west-2"
    }
  }
  description = "Routes added to vpc_c route tables (London)"
}
