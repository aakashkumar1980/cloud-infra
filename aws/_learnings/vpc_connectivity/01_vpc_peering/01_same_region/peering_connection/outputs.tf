/**
 * Peering Connection Module - Outputs
 */

output "peering_connection_id" {
  value       = aws_vpc_peering_connection.peering_vpc_a_to_vpc_b.id
  description = "VPC Peering Connection ID"
}

output "peering_connection_status" {
  value       = aws_vpc_peering_connection.peering_vpc_a_to_vpc_b.accept_status
  description = "VPC Peering Connection status (should be 'active')"
}
