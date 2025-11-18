/**
 * Outputs the IDs of the created Internet Gateways.
 */
output "igw_ids" {
  value = { for k, v in aws_internet_gateway.this : k => v.id }
}

/**
 * Outputs the Name tags of the created Internet Gateways.
 */
output "igw_names" {
  value = { for k, v in aws_internet_gateway.this : k => v.tags["Name"] }
}
