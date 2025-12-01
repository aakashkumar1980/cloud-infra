/**
 * Routes Module - Outputs
 */

output "vpc_a_routes" {
  value       = [for r in aws_route.route_vpc_a_to_vpc_b : "${r.route_table_id} -> ${r.destination_cidr_block}"]
  description = "Routes added to vpc_a route tables"
}

output "vpc_b_routes" {
  value       = [for r in aws_route.route_vpc_b_to_vpc_a : "${r.route_table_id} -> ${r.destination_cidr_block}"]
  description = "Routes added to vpc_b route tables"
}
