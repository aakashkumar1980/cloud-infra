/**
 * Outputs
 *
 * Exposes cross-region VPC peering connection details and routing information.
 */

locals {
  peering_tag_name = "peering-vpc_a-to-vpc_c-${local.REGION_N_VIRGINIA}-to-${local.REGION_LONDON}-${var.profile}-terraform"
}

/**
 * 1. VPC Peering Connection Details
 */
output "vpc_peering" {
  value = {
    name   = local.peering_tag_name
    status = module.peering_connection.peering_connection_status
    vpc_a = {
      name   = local.vpc_a_name
      cidr   = data.aws_vpc.vpc_a.cidr_block
      region = local.regions_cfg[local.REGION_N_VIRGINIA]
    }
    vpc_c = {
      name   = local.vpc_c_name
      cidr   = data.aws_vpc.vpc_c.cidr_block
      region = local.regions_cfg[local.REGION_LONDON]
    }
  }
  description = "Cross-Region VPC Peering Connection: name, status, and connected VPCs with regions"
}

/**
 * 2. Route Table Details with New Routes
 */
output "route_tables" {
  value = {
    vpc_a = {
      region = local.regions_cfg[local.REGION_N_VIRGINIA]
      routes = {
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
              if route.cidr_block != data.aws_vpc.vpc_c.cidr_block
            ],
            # New peering route (marked with *)
            [
              {
                destination = data.aws_vpc.vpc_c.cidr_block
                target_name = "${local.peering_tag_name} *"
                type        = "vpc_peering_connection"
              }
            ]
          )
        }
      }
    }
    vpc_c = {
      region = local.regions_cfg[local.REGION_LONDON]
      routes = {
        for name, rt in data.aws_route_table.vpc_c : name => {
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
  }
  description = "Route tables with existing and new routes (* marks new peering routes)"
}

/**
 * 3. Test Instructions
 */
output "test_instructions" {
  value       = var.enable_test ? module.test[0].test_instructions : "Test disabled. Set enable_test = true to create test instances."
  description = "Instructions for testing cross-region VPC peering connectivity"
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
