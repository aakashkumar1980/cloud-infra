/**
 * Local Variables
 *
 * Loads configuration files from /aws/configs for consistent tagging
 * and network configuration across all learning modules.
 *
 * Config files loaded:
 *   - configs/tags.yaml              -> Global and environment tags
 *   - configs/<profile>/networking.json -> VPC and subnet definitions
 */
locals {
  REGION_N_VIRGINIA = "nvirginia"
  regions_cfg = {
    (local.REGION_N_VIRGINIA) = "us-east-1"
  }

  config_dir = abspath("${path.module}/../../../../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")
  tags_cfg   = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking = jsondecode(file("${local.env_dir}/networking.json"))
  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  name_suffix_nvirginia = "${local.REGION_N_VIRGINIA}-${var.profile}-${local.tags_common["managed_by"]}"
  vpc_a_name = "vpc_a-${local.name_suffix_nvirginia}"
  vpc_b_name = "vpc_b-${local.name_suffix_nvirginia}"

  vpcs_nvirginia = try(local.networking.regions[local.REGION_N_VIRGINIA].vpcs, {})

  # Subnet configuration (keyed by subnet identifier for lookups)
  vpc_a_subnets = {
    for subnet in local.vpcs_nvirginia.vpc_a.subnets :
    "${subnet.tier}_zone_${subnet.zone}" => {
      name    = "subnet_${subnet.tier}_zone_${subnet.zone}-vpc_a-${local.name_suffix_nvirginia}"
      cidr    = subnet.cidr
      tier    = subnet.tier
      zone    = subnet.zone
      rt_name = "routetable-subnet_${subnet.tier}_zone_${subnet.zone}-vpc_a-${local.name_suffix_nvirginia}"
    }
  }
  vpc_b_subnets = {
    for subnet in local.vpcs_nvirginia.vpc_b.subnets :
    "${subnet.tier}_zone_${subnet.zone}" => {
      name    = "subnet_${subnet.tier}_zone_${subnet.zone}-vpc_b-${local.name_suffix_nvirginia}"
      cidr    = subnet.cidr
      tier    = subnet.tier
      zone    = subnet.zone
      rt_name = "routetable-subnet_${subnet.tier}_zone_${subnet.zone}-vpc_b-${local.name_suffix_nvirginia}"
    }
  }

  # Route table names (for data source lookups)
  vpc_a_route_table_names = [for s in local.vpc_a_subnets : s.rt_name]
  vpc_b_route_table_names = [for s in local.vpc_b_subnets : s.rt_name]
}
