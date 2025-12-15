/**
 * Local Variables
 *
 * Loads configuration files from /aws/configs for consistent tagging
 * and network configuration across all learning modules.
 *
 * Config files loaded:
 *   - configs/tags.yaml              -> Global and environment tags
 *   - configs/<profile>/networking.json -> VPC and subnet definitions
 *
 * Cross-Region Peering Setup:
 *   - N. Virginia (us-east-1): vpc_a (10.0.0.0/24) - Requester
 *   - London (eu-west-2):      vpc_c (192.168.0.0/26) - Accepter
 */
locals {
  REGION_N_VIRGINIA = "nvirginia"
  REGION_LONDON     = "london"

  regions_cfg = {
    (local.REGION_N_VIRGINIA) = "us-east-1"
    (local.REGION_LONDON)     = "eu-west-2"
  }

  config_dir = abspath("${path.module}/../../../../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")
  tags_cfg   = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking = jsondecode(file("${local.env_dir}/networking.json"))
  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  # Name suffixes for each region
  name_suffix_nvirginia = "${local.REGION_N_VIRGINIA}-${var.profile}-${local.tags_common["managed_by"]}"
  name_suffix_london    = "${local.REGION_LONDON}-${var.profile}-${local.tags_common["managed_by"]}"

  # VPC names following base_network naming convention
  vpc_a_name = "vpc_a-${local.name_suffix_nvirginia}"
  vpc_c_name = "vpc_c-${local.name_suffix_london}"

  # Get VPCs from networking config
  vpcs_nvirginia = try(local.networking.regions[local.REGION_N_VIRGINIA].vpcs, {})
  vpcs_london    = try(local.networking.regions[local.REGION_LONDON].vpcs, {})

  # Subnet configuration for vpc_a (N. Virginia)
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

  # Subnet configuration for vpc_c (London)
  vpc_c_subnets = {
    for subnet in local.vpcs_london.vpc_c.subnets :
    "${subnet.tier}_zone_${subnet.zone}" => {
      name    = "subnet_${subnet.tier}_zone_${subnet.zone}-vpc_c-${local.name_suffix_london}"
      cidr    = subnet.cidr
      tier    = subnet.tier
      zone    = subnet.zone
      rt_name = "routetable-subnet_${subnet.tier}_zone_${subnet.zone}-vpc_c-${local.name_suffix_london}"
    }
  }

  # Route table names (for backwards compatibility)
  vpc_a_route_table_names = [for s in local.vpc_a_subnets : s.rt_name]
  vpc_c_route_table_names = [for s in local.vpc_c_subnets : s.rt_name]
}
