/**
 * Outputs for Public Route Tables
 *
 * Exposes route table IDs, names, and routing information
 * for use by parent modules and for display purposes.
 */

/**
 * @output route_table_ids - AWS resource IDs for each public route table
 *         Key: subnet key (e.g., "vpc_a/public_zone_a")
 *         Value: route table ID (e.g., "rtb-abc123")
 */
output "route_table_ids" {
  value       = { for k, v in aws_route_table.public : k => v.id }
  description = "Map of public subnet keys to route table IDs"
}

/**
 * @output route_table_names - Name tags for each public route table
 *         Useful for display in AWS Console and CLI output
 */
output "route_table_names" {
  value       = { for k, v in aws_route_table.public : k => v.tags["Name"] }
  description = "Map of public subnet keys to route table Name tags"
}

/**
 * @output route_table_routes - Detailed routing information
 *         Shows what routes each table contains:
 *           - destination: The CIDR block being routed (0.0.0.0/0 for internet)
 *           - target_name: Name of the Internet Gateway
 *           - type: "internet_gateway"
 *           - vpc_cidr: "local" (VPC internal traffic stays local)
 */
output "route_table_routes" {
  value = {
    for k, v in aws_route_table.public : v.tags["Name"] => {
      routes = [
        {
          destination = "0.0.0.0/0"
          target_name = "igw-${local.public_subnets[k].vpc_name}-${var.common_tags["region"]}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
          type        = "internet_gateway"
        }
      ]
      vpc_cidr = "local"
    }
  }
  description = "Public route table routing rules showing destination and target gateway"
}
