/**
 * Outputs
 *
 * Exposes cross-region VPC peering connection details and routing information
 * in a hierarchical structure organized by region and VPC.
 */

locals {
  peering_tag_name = "peering-vpc_a-to-vpc_c-${local.REGION_N_VIRGINIA}-to-${local.REGION_LONDON}-${var.profile}-terraform"
}

/**
 * Cross-Region VPC Peering - Hierarchical Network Infrastructure
 *
 * Shows: VPC Peering -> Regions -> VPCs -> Subnets -> Route Table -> Routes, EC2 -> Security Groups
 */
output "network" {
  description = "Cross-region network infrastructure hierarchy"
  value = {
    vpc_peering = {
      name   = local.peering_tag_name
      status = module.peering_connection.peering_connection_status
    }

    nvirginia = {
      region = local.regions_cfg[local.REGION_N_VIRGINIA]

      vpc_a = {
        name = local.vpc_a_name
        cidr = data.aws_vpc.vpc_a.cidr_block

        subnets = {
          for subnet_key, subnet in data.aws_subnet.vpc_a : subnet.tags["Name"] => {
            cidr = subnet.cidr_block

            route_table = {
              name = data.aws_route_table.vpc_a[subnet_key].tags["Name"]
              routes = concat(
                [
                  for route in data.aws_route_table.vpc_a[subnet_key].routes :
                  "${route.cidr_block} -> ${
                    try(length(route.gateway_id), 0) > 0 ? route.gateway_id : (
                      try(length(route.nat_gateway_id), 0) > 0 ? route.nat_gateway_id : (
                        try(length(route.vpc_peering_connection_id), 0) > 0 ? "peering-${route.vpc_peering_connection_id}" : "local"
                      )
                    )
                  }"
                  if route.cidr_block != data.aws_vpc.vpc_c.cidr_block
                ],
                ["${data.aws_vpc.vpc_c.cidr_block} -> ${local.peering_tag_name} *"]
              )
            }

            ec2 = var.enable_test ? (
              subnet_key == "public_zone_a" ? {
                name       = module.test[0].test_summary.instances.bastion.name
                private_ip = module.test[0].test_summary.instances.bastion.private_ip
                public_ip  = module.test[0].test_summary.instances.bastion.public_ip
                security_group = {
                  name = module.test[0].test_summary.security_groups.bastion.name
                  rules = [
                    for rule in module.test[0].test_summary.security_groups.bastion.ingress_rules :
                    "${rule.type} | ${rule.port_range} | ${rule.source}"
                  ]
                }
              } : (
                subnet_key == "private_zone_a" ? {
                  name       = module.test[0].test_summary.instances.vpc_a_private.name
                  private_ip = module.test[0].test_summary.instances.vpc_a_private.private_ip
                  public_ip  = module.test[0].test_summary.instances.vpc_a_private.public_ip
                  security_group = {
                    name = module.test[0].test_summary.security_groups.vpc_a_private.name
                    rules = [
                      for rule in module.test[0].test_summary.security_groups.vpc_a_private.ingress_rules :
                      "${rule.type} | ${rule.port_range} | ${rule.source}"
                    ]
                  }
                } : null
              )
            ) : null
          }
        }
      }
    }

    london = {
      region = local.regions_cfg[local.REGION_LONDON]

      vpc_c = {
        name = local.vpc_c_name
        cidr = data.aws_vpc.vpc_c.cidr_block

        subnets = {
          for subnet_key, subnet in data.aws_subnet.vpc_c : subnet.tags["Name"] => {
            cidr = subnet.cidr_block

            route_table = {
              name = data.aws_route_table.vpc_c[subnet_key].tags["Name"]
              routes = concat(
                [
                  for route in data.aws_route_table.vpc_c[subnet_key].routes :
                  "${route.cidr_block} -> ${
                    try(length(route.gateway_id), 0) > 0 ? route.gateway_id : (
                      try(length(route.nat_gateway_id), 0) > 0 ? route.nat_gateway_id : (
                        try(length(route.vpc_peering_connection_id), 0) > 0 ? "peering-${route.vpc_peering_connection_id}" : "local"
                      )
                    )
                  }"
                  if route.cidr_block != data.aws_vpc.vpc_a.cidr_block
                ],
                ["${data.aws_vpc.vpc_a.cidr_block} -> ${local.peering_tag_name} *"]
              )
            }

            ec2 = var.enable_test ? (
              subnet_key == "private_zone_c" ? {
                name       = module.test[0].test_summary.instances.vpc_c_private.name
                private_ip = module.test[0].test_summary.instances.vpc_c_private.private_ip
                public_ip  = module.test[0].test_summary.instances.vpc_c_private.public_ip
                security_group = {
                  name = module.test[0].test_summary.security_groups.vpc_c_private.name
                  rules = [
                    for rule in module.test[0].test_summary.security_groups.vpc_c_private.ingress_rules :
                    "${rule.type} | ${rule.port_range} | ${rule.source}"
                  ]
                }
              } : null
            ) : null
          }
        }
      }
    }
  }
}

/**
 * Test Instructions
 */
output "test_instructions" {
  value       = var.enable_test ? module.test[0].test_instructions : "Test disabled. Set enable_test = true to create test instances."
  description = "Instructions for testing cross-region VPC peering connectivity"
}

/** Private Key Output (sensitive) */
output "test_private_key_pem" {
  value       = var.enable_test ? module.test[0].private_key_pem : null
  sensitive   = true
  description = "Private key PEM for SSH access"
}
