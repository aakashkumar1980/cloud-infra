/**
 * Outputs the IDs of the created route tables.
 */
output "route_table_ids" {
  value = { for k, v in aws_route_table.public : k => v.id }
}

/**
 * Outputs the Name tags of the created route tables.
 */
output "route_table_names" {
  value = { for k, v in aws_route_table.public : k => v.tags["Name"] }
}

/**
 * Outputs the route information including source (implicit local route) and destinations.
 * For each route table, shows the destination CIDR and gateway (IGW Name tag).
 */
output "route_table_routes" {
  value = {
    for k, v in aws_route_table.public : k => {
      routes = [
        {
          destination = "0.0.0.0/0"
          target      = lookup(var.igw_ids, local.public_subnets[k].vpc_name, "")
          target_name = "igw-${local.public_subnets[k].vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
          type        = "internet_gateway"
        }
      ]
      vpc_cidr = "local" # The VPC CIDR has an implicit local route
    }
  }
}
