# Route table IDs
output "route_table_ids" {
  value       = { for k, v in aws_route_table.private : k => v.id }
  description = "Map of private subnet keys to route table IDs"
}

# Route table names
output "route_table_names" {
  value       = { for k, v in aws_route_table.private : k => v.tags["Name"] }
  description = "Map of private subnet keys to route table names"
}

# Route information (destination -> target)
output "route_table_routes" {
  value = {
    for k, v in aws_route_table.private : v.tags["Name"] => {
      routes = [
        {
          destination = "0.0.0.0/0"
          target_name = "natgw-${local.private_subnets[k].vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
          type        = "nat_gateway"
        }
      ]
      vpc_cidr = "local"
    }
  }
}
