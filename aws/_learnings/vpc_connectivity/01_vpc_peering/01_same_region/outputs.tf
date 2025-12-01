/**
 * Outputs
 *
 * Exposes VPC peering connection details and routing information.
 */

output "peering_connection_id" {
  value       = aws_vpc_peering_connection.vpc_a_to_vpc_b.id
  description = "VPC Peering Connection ID"
}

output "peering_connection_status" {
  value       = aws_vpc_peering_connection.vpc_a_to_vpc_b.accept_status
  description = "VPC Peering Connection status (should be 'active')"
}

output "vpc_a_info" {
  value = {
    id         = data.aws_vpc.vpc_a.id
    cidr_block = data.aws_vpc.vpc_a.cidr_block
    name       = var.vpc_a_name
  }
  description = "VPC A (requester) information"
}

output "vpc_b_info" {
  value = {
    id         = data.aws_vpc.vpc_b.id
    cidr_block = data.aws_vpc.vpc_b.cidr_block
    name       = var.vpc_b_name
  }
  description = "VPC B (accepter) information"
}

output "routes_added" {
  value = {
    vpc_a_routes = [for r in aws_route.vpc_a_to_vpc_b : "${r.route_table_id} -> ${r.destination_cidr_block}"]
    vpc_b_routes = [for r in aws_route.vpc_b_to_vpc_a : "${r.route_table_id} -> ${r.destination_cidr_block}"]
  }
  description = "Routes added to each VPC's route tables"
}

output "peering_summary" {
  value = <<-EOT

    ╔══════════════════════════════════════════════════════════════════╗
    ║                    VPC PEERING CONNECTION                        ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║   vpc_a (${data.aws_vpc.vpc_a.cidr_block})                                      ║
    ║      │                                                           ║
    ║      │  Peering: ${aws_vpc_peering_connection.vpc_a_to_vpc_b.id}               ║
    ║      │                                                           ║
    ║      ▼                                                           ║
    ║   vpc_b (${data.aws_vpc.vpc_b.cidr_block})                                    ║
    ║                                                                  ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║   Status: ${aws_vpc_peering_connection.vpc_a_to_vpc_b.accept_status}                                              ║
    ╚══════════════════════════════════════════════════════════════════╝

  EOT
  description = "Visual summary of the peering connection"
}

/** Test Module Outputs */
output "test_instructions" {
  value       = var.enable_test ? module.test[0].test_instructions : "Test disabled. Set enable_test = true to create test instances."
  description = "Instructions for testing VPC peering connectivity"
}

output "test_summary" {
  value       = var.enable_test ? module.test[0].test_summary : null
  description = "Summary of test instances (null if tests disabled)"
}
