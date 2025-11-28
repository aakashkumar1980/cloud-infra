/**
 * Local Variables
 *
 * Loads configuration files and prepares data for child modules.
 *
 * Config files loaded:
 *   - configs/regions.yaml      -> Region name mappings
 *   - configs/tags.yaml         -> Global and environment tags
 *   - configs/<profile>/networking.json -> VPC and subnet definitions
 *
 * Key transformations:
 *   - Merges global tags with environment-specific tags
 *   - Extracts VPC configs for each region
 *   - Maps zone letters (a, b, c) to array indices (0, 1, 2)
 */
locals {
  config_dir = abspath("${path.module}/../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")

  regions_cfg = yamldecode(file("${local.config_dir}/regions.yaml"))
  tags_cfg    = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking  = jsondecode(file("${local.env_dir}/networking.json"))

  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  vpcs_nvirginia  = try(local.networking.regions["nvirginia"].vpcs, {})
  vpcs_london     = try(local.networking.regions["london"].vpcs, {})
  az_letter_to_ix = { a = 0, b = 1, c = 2 }
}
