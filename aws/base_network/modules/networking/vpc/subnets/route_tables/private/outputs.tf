/**
 * Outputs for Private Route Tables
 *
 * Exposes route table IDs, names, and routing information
 * for use by parent modules and for display purposes.
 */

/**
 * @output route_table_ids - AWS resource IDs for each private route table
 *         Key: subnet key (e.g., "vpc_a/private_zone_b")
 *         Value: route table ID (e.g., "rtb-xyz789")
 */
output "route_table_ids" {
  value       = { for k, v in aws_route_table.private_rt : k => v.id }
  description = "Map of private subnet keys to route table IDs"
}

/**
 * @output route_table_names - Name tags for each private route table
 *         Useful for display in AWS Console and CLI output
 */
output "route_table_names" {
  value       = { for k, v in aws_route_table.private_rt : k => v.tags["Name"] }
  description = "Map of private subnet keys to route table Name tags"
}

/**
 * @output route_table_routes - Detailed routing information
 *         Shows what routes each table contains:
 *           - destination: The CIDR block being routed (0.0.0.0/0 for internet)
 *           - target_name: Name of the NAT Gateway
 *           - type: "nat_gateway"
 *           - vpc_cidr: "local" (VPC internal traffic stays local)
 */
output "route_table_routes" {
  value = {
    for k, v in aws_route_table.private_rt : v.tags["Name"] => {
      routes = [
        {
          destination = "0.0.0.0/0"
          target_name = "natgw-${local.private_subnets[k].vpc_name}-${var.name_suffix}"
          type        = "nat_gateway"
        }
      ]
      vpc_cidr = "local"
    }
  }
  description = "Private route table routing rules showing destination and target NAT Gateway"
}
