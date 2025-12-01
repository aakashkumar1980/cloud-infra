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
  config_dir = abspath("${path.module}/../../../../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")

  tags_cfg   = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking = jsondecode(file("${local.env_dir}/networking.json"))

  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  # VPC configurations from networking.json
  vpcs_nvirginia = try(local.networking.regions["nvirginia"].vpcs, {})

  # Derive Name tags using base_network naming convention: {vpc_name}-{name_suffix}
  vpc_a_name = "vpc_a-${var.name_suffix}"
  vpc_b_name = "vpc_b-${var.name_suffix}"
}
