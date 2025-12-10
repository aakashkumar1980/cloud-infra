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
  name_suffix_nvirginia = "${local.REGION_N_VIRGINIA}-${var.profile}-terraform"
  name_suffix_london    = "${local.REGION_LONDON}-${var.profile}-terraform"

  # VPC names following base_network naming convention
  vpc_a_name = "vpc_a-${local.name_suffix_nvirginia}"
  vpc_c_name = "vpc_c-${local.name_suffix_london}"

  # Get VPCs from networking config
  vpcs_nvirginia = try(local.networking.regions[local.REGION_N_VIRGINIA].vpcs, {})
  vpcs_london    = try(local.networking.regions[local.REGION_LONDON].vpcs, {})

}
