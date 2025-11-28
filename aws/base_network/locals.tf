# Load configuration files and prepare data for modules

locals {
  # Config directory paths
  config_dir = abspath("${path.module}/../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")

  # Load config files
  regions_cfg = yamldecode(file("${local.config_dir}/regions.yaml"))
  tags_cfg    = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking  = jsondecode(file("${local.env_dir}/networking.json"))

  # Merge global tags with environment-specific tags
  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  # Extract VPC configs per region
  vpcs_nvirginia = try(local.networking.regions["nvirginia"].vpcs, {})
  vpcs_london    = try(local.networking.regions["london"].vpcs, {})

  # Map zone letters (a, b, c) to array indices (0, 1, 2)
  az_letter_to_ix = { a = 0, b = 1, c = 2 }
}
