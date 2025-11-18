/**
 * Outputs the IDs of the created Internet Gateways.
 */
output "igw_ids" {
  value = { for k, v in aws_internet_gateway.this : k => v.id }
}
