/**
 * Outputs
 *
 * Exposes VPC peering connection details and routing information.
 */

locals {
  peering_tag_name = "test_peering-vpc_a-to-vpc_b-${local.name_suffix_nvirginia}"
}

/**
 * 1. VPC Peering Connection Details
 */
output "vpc_peering" {
  value = {
    name   = local.peering_tag_name
    status = module.peering_connection.peering_connection_status
    vpc_a = {
      name = local.vpc_a_name
      cidr = data.aws_vpc.vpc_a.cidr_block
    }
    vpc_b = {
      name = local.vpc_b_name
      cidr = data.aws_vpc.vpc_b.cidr_block
    }
  }
  description = "VPC Peering Connection: name, status, and connected VPCs"
}

/**
 * 2. Route Table Details with New Routes
 */
output "route_tables" {
  value = {
    vpc_a = {
      for name, rt in data.aws_route_table.vpc_a : name => {
        name = name
        routes = concat(
          # Existing routes (not managed by this module)
          [
            for route in rt.routes : {
              destination = route.cidr_block
              target_name = route.gateway_id != "" ? route.gateway_id : (route.nat_gateway_id != "" ? route.nat_gateway_id : "local")
              type        = route.gateway_id != "" ? "internet_gateway" : (route.nat_gateway_id != "" ? "nat_gateway" : "local")
            }
            if route.cidr_block != data.aws_vpc.vpc_b.cidr_block
          ],
          # New peering route (marked with *)
          [
            {
              destination = data.aws_vpc.vpc_b.cidr_block
              target_name = "${local.peering_tag_name} *"
              type        = "vpc_peering_connection"
            }
          ]
        )
      }
    }
    vpc_b = {
      for name, rt in data.aws_route_table.vpc_b : name => {
        name = name
        routes = concat(
          # Existing routes (not managed by this module)
          [
            for route in rt.routes : {
              destination = route.cidr_block
              target_name = route.gateway_id != "" ? route.gateway_id : (route.nat_gateway_id != "" ? route.nat_gateway_id : "local")
              type        = route.gateway_id != "" ? "internet_gateway" : (route.nat_gateway_id != "" ? "nat_gateway" : "local")
            }
            if route.cidr_block != data.aws_vpc.vpc_a.cidr_block
          ],
          # New peering route (marked with *)
          [
            {
              destination = data.aws_vpc.vpc_a.cidr_block
              target_name = "${local.peering_tag_name} *"
              type        = "vpc_peering_connection"
            }
          ]
        )
      }
    }
  }
  description = "Route tables with existing and new routes (* marks new peering routes)"
}

/**
 * 3. Test Instructions
 */
output "test_instructions" {
  value       = var.enable_test ? module.test[0].test_instructions : "Test disabled. Set enable_test = true to create test instances."
  description = "Instructions for testing VPC peering connectivity"
}

/**
 * 4. Test Summary
 */
output "test_summary" {
  value       = var.enable_test ? module.test[0].test_summary : null
  description = "Test summary: security groups with ingress rules, key pair, and EC2 instances"
}

/** Private Key Output (sensitive) */
output "test_private_key_pem" {
  value       = var.enable_test ? module.test[0].private_key_pem : null
  sensitive   = true
  description = "Private key PEM for SSH access"
}
