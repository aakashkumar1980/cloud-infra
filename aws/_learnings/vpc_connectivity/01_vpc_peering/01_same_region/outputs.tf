/**
 * Outputs
 *
 * Exposes VPC peering connection details and routing information.
 */

output "peering_connection_id" {
  value       = module.peering_connection.peering_connection_id
  description = "VPC Peering Connection ID"
}

output "peering_connection_status" {
  value       = module.peering_connection.peering_connection_status
  description = "VPC Peering Connection status (should be 'active')"
}

output "vpc_a_info" {
  value = {
    id         = data.aws_vpc.vpc_a.id
    cidr_block = data.aws_vpc.vpc_a.cidr_block
    name       = local.vpc_a_name
  }
  description = "VPC A (requester) information"
}

output "vpc_b_info" {
  value = {
    id         = data.aws_vpc.vpc_b.id
    cidr_block = data.aws_vpc.vpc_b.cidr_block
    name       = local.vpc_b_name
  }
  description = "VPC B (accepter) information"
}

output "routes_added" {
  value = {
    vpc_a_routes = module.routes.vpc_a_routes
    vpc_b_routes = module.routes.vpc_b_routes
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
    ║      │  Peering: ${module.peering_connection.peering_connection_id}               ║
    ║      │                                                           ║
    ║      ▼                                                           ║
    ║   vpc_b (${data.aws_vpc.vpc_b.cidr_block})                                    ║
    ║                                                                  ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║   Status: ${module.peering_connection.peering_connection_status}                                              ║
    ╚══════════════════════════════════════════════════════════════════╝

  EOT
  description = "Visual summary of the peering connection"
}

/** Test Module Outputs */
output "test_key_name" {
  value       = var.enable_test ? module.test[0].key_name : null
  description = "SSH key pair name (null if tests disabled)"
}

output "test_private_key_pem" {
  value       = var.enable_test ? module.test[0].private_key_pem : null
  sensitive   = true
}

output "test_instructions" {
  value       = var.enable_test ? module.test[0].test_instructions : "Test disabled. Set enable_test = true to create test instances."
  description = "Instructions for testing VPC peering connectivity"
}

output "test_summary" {
  value       = var.enable_test ? module.test[0].test_summary : null
  description = "Summary of test instances (null if tests disabled)"
}
