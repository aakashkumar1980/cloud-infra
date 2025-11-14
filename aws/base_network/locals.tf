/**
 * Locals
 *
 * - Compute absolute paths to config directories.
 * - Load shared (tags.yaml) and environment-specific (networking.yaml).
 * - Merge all-lowercase tags into common set.
 * - Extract region-specific VPC maps for cleaner passing to modules.
 *
 * Folder layout assumption:
 *   base_network/
 *   ../configs/tags.yaml
 *   ../configs/firewalls.yaml
 *   ../configs/<profile>/networking.yaml
 *   ../configs/<profile>/amis.yaml
 */
locals {
  // Paths
  config_dir = abspath("${path.module}/../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")

  // Config files
  regions_cfg = yamldecode(file("${local.config_dir}/regions.yaml"))
  tags_cfg    = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking  = jsondecode(file("${local.env_dir}/networking.json"))

  // Tags (all-lowercase keys, per your convention)
  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  // Region-scoped VPC maps (safe if region is missing)
  vpcs_nvirginia = try(local.networking.regions["nvirginia"].vpcs, {})
  vpcs_london = try(local.networking.regions["london"].vpcs, {})

  // AZ letter → numeric index mapping (a=0, b=1, c=2)
  az_letter_to_ix = { a = 0, b = 1, c = 2 }
}
