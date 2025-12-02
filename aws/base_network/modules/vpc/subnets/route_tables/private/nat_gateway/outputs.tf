/**
 * Outputs
 *
 * Exposes NAT Gateway IDs, public IPs, and names.
 * Used by private route tables to route internet traffic.
 */

/** NAT Gateway IDs - used by private route tables */
output "nat_gateway_ids" {
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
  description = "Map of VPC names to NAT Gateway IDs"
}

/** NAT Gateway public IPs */
output "nat_gateway_public_ips" {
  value       = { for k, v in aws_nat_gateway.this : k => v.public_ip }
  description = "Map of VPC names to NAT Gateway public IPs"
}

/** NAT Gateway name tags - just the Name tag value */
output "nat_gateway_name_tags" {
  value       = { for k, v in aws_nat_gateway.this : k => v.tags["Name"] }
  description = "Map of VPC names to NAT Gateway Name tags"
}

/** NAT Gateway names with IGW relationship */
output "nat_gateway_names" {
  value       = { for k, v in aws_nat_gateway.this : k => "${v.tags["Name"]} -> ${var.igw_names[k]}" }
  description = "Map of VPC names to NAT Gateway names showing routing path"
}

/** Elastic IP allocation IDs */
output "eip_allocation_ids" {
  value       = { for k, v in aws_eip.eip : k => v.id }
  description = "Map of VPC names to EIP allocation IDs"
}
