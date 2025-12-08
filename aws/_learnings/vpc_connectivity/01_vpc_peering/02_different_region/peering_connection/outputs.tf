/**
 * Peering Connection Module - Outputs (Cross-Region)
 */

output "peering_connection_id" {
  value       = aws_vpc_peering_connection.peering_vpc_a_to_vpc_c.id
  description = "VPC Peering Connection ID"
}

output "peering_connection_status" {
  value       = aws_vpc_peering_connection_accepter.accepter.accept_status
  description = "VPC Peering Connection status (should be 'active' after acceptance)"
}

output "requester_vpc_id" {
  value       = aws_vpc_peering_connection.peering_vpc_a_to_vpc_c.vpc_id
  description = "Requester VPC ID (N. Virginia)"
}

output "accepter_vpc_id" {
  value       = aws_vpc_peering_connection.peering_vpc_a_to_vpc_c.peer_vpc_id
  description = "Accepter VPC ID (London)"
}
