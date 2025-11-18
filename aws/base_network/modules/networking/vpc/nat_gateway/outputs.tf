/**
 * Outputs the IDs of the created NAT Gateways.
 * Used by private route tables to route traffic to the internet.
 */
output "nat_gateway_ids" {
  value = { for k, v in aws_nat_gateway.this : k => v.id }
  description = "Map of VPC names to NAT Gateway IDs"
}

/**
 * Outputs the public IP addresses of the created NAT Gateways.
 * These are the Elastic IP addresses associated with each NAT Gateway.
 */
output "nat_gateway_public_ips" {
  value = { for k, v in aws_nat_gateway.this : k => v.public_ip }
  description = "Map of VPC names to NAT Gateway public IP addresses"
}

/**
 * Outputs the Name tags of the created NAT Gateways.
 */
output "nat_gateway_names" {
  value = { for k, v in aws_nat_gateway.this : k => v.tags["Name"] }
  description = "Map of VPC names to NAT Gateway names"
}

/**
 * Outputs the Elastic IP allocation IDs.
 */
output "eip_allocation_ids" {
  value = { for k, v in aws_eip.nat : k => v.id }
  description = "Map of VPC names to EIP allocation IDs"
}
