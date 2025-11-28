# Route table IDs
output "route_table_ids" {
  value = { for k, v in aws_route_table.public : k => v.id }
}

# Route table names
output "route_table_names" {
  value = { for k, v in aws_route_table.public : k => v.tags["Name"] }
}

# Route information (destination -> target)
output "route_table_routes" {
  value = {
    for k, v in aws_route_table.public : v.tags["Name"] => {
      routes = [
        {
          destination = "0.0.0.0/0"
          target_name = "igw-${local.public_subnets[k].vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
          type        = "internet_gateway"
        }
      ]
      vpc_cidr = "local"
    }
  }
}
