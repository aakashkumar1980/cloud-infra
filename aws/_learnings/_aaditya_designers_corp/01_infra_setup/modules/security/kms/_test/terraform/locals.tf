/**
 * Local Variables for KMS _test Module
 *
 * Loads configuration files from /aws/configs for consistent tagging
 * across all test modules.
 *
 * Config files loaded:
 *   - configs/tags.yaml              -> Global and environment tags
 */
locals {
  REGION_N_VIRGINIA = "nvirginia"

  regions_cfg = {
    (local.REGION_N_VIRGINIA) = "us-east-1"
  }

  # Path to shared configs (8 levels up from terraform/ to aws/)
  config_dir = abspath("${path.module}/../../../../../../../../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")
  tags_cfg   = yamldecode(file("${local.config_dir}/tags.yaml"))

  tags_common = merge(
    local.tags_cfg.global_tags,
    lookup(local.tags_cfg.environment_tags, var.profile, {})
  )

  # Increment component version if there are breaking changes to test components
  component_version = "v1"
  # Name suffix with test_ prefix to distinguish from production resources
  name_suffix = "${local.REGION_N_VIRGINIA}-${var.profile}-${local.tags_common["company"]}_${local.component_version}-${local.tags_common["managed_by"]}"
}
