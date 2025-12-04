/**
 * Local Variables
 *
 * Loads configuration files and prepares data for child modules.
 *
 * Config files loaded:
 *   - configs/tags.yaml         -> Global and environment tags
 *   - configs/<profile>/networking.json -> VPC and subnet definitions
 *
 * Key transformations:
 *   - Merges global tags with environment-specific tags
 *   - Dynamically extracts VPC configs for each region
 *   - Maps zone letters (a, b, c) to array indices (0, 1, 2)
 *
 * Adding a new region:
 *   1. Add region key and AWS region code to `regions` map below
 *   2. Add provider block in providers.tf
 *   3. Add data source and module block in main.tf
 */
locals {
  # ─────────────────────────────────────────────────────────────────────────────
  # Region Configuration (Single source of truth)
  # Maps friendly region names to AWS region codes
  # ─────────────────────────────────────────────────────────────────────────────
  regions = {
    nvirginia = "us-east-1"
    london    = "eu-west-2"
  }

  # ─────────────────────────────────────────────────────────────────────────────
  # Configuration Files
  # ─────────────────────────────────────────────────────────────────────────────
  config_dir = abspath("${path.module}/../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")
  tags_cfg   = yamldecode(file("${local.config_dir}/tags.yaml"))
  networking = jsondecode(file("${local.env_dir}/networking.json"))

  # ─────────────────────────────────────────────────────────────────────────────
  # Common Tags
  # ─────────────────────────────────────────────────────────────────────────────
  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  # ─────────────────────────────────────────────────────────────────────────────
  # VPC Configurations (Dynamically extracted per region)
  # Each region's VPCs are pulled from networking.json
  # ─────────────────────────────────────────────────────────────────────────────
  vpcs = {
    for region_key, aws_region in local.regions :
    region_key => try(local.networking.regions[region_key].vpcs, {})
  }

  # ─────────────────────────────────────────────────────────────────────────────
  # Availability Zone Mapping
  # Maps zone letters to array indices for subnet placement
  # ─────────────────────────────────────────────────────────────────────────────
  az_letter_to_ix = { a = 0, b = 1, c = 2 }
}
