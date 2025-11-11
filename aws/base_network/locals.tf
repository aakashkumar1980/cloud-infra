/**
 * This variable defines the deployment environment profile, and
 * is used to load environment-specific configurations.
 * Example usage:
 * terraform apply -var="profile=dev"
 */
variable "profile" {
  description = "Deployment environment profile (e.g. dev, qa, prod)"
  type        = string
}

/**
 * Local variables to load and merge configuration files.
 */
locals {
  config_dir = abspath("${path.module}/../configs")
  env_dir    = abspath("${local.config_dir}/${var.profile}")

  # Load shared configs
  firewall = yamldecode(file("${local.config_dir}/firewall.yaml"))
  tags     = yamldecode(file("${local.config_dir}/tags.yaml"))

  # Load environment-specific configs dynamically
  amis       = yamldecode(file("${local.env_dir}/amis.yaml"))
  networking = yamldecode(file("${local.env_dir}/networking.yaml"))

  # Merge tags for current environment
  merged_tags = merge(
    local.tags.global_tags,
    lookup(local.tags.environment_tags, var.profile, {})
  )
}
