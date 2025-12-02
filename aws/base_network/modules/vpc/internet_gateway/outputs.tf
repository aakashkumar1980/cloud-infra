/**
 * Outputs
 *
 * @output igw_ids   - Map of VPC names to Internet Gateway IDs
 * @output igw_names - Map of VPC names to Internet Gateway Name tags
 */
output "igw_ids" {
  value       = { for k, v in aws_internet_gateway.this : k => v.id }
  description = "Map of VPC names to Internet Gateway IDs"
}

output "igw_names" {
  value       = { for k, v in aws_internet_gateway.this : k => v.tags["Name"] }
  description = "Map of VPC names to Internet Gateway Name tags"
}
