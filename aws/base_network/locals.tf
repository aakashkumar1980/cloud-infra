/**
 * This variable defines the deployment environment profile, and
 * is used to load environment-specific configurations.
 * Example usage:
 * terraform apply -var="profile=dev"
 */
variable "profile" {
  description = "Deployment environment profile (e.g. dev, stage, prod)"
  type        = string
}

/**
 * Local variables to load and merge configuration files.
 */
locals {
  # Load shared configs
  firewall = yamldecode(file("${path.module}/../../configs/firewall.yaml"))
  tags     = yamldecode(file("${path.module}/../../configs/tags.yaml"))

  # Load environment-specific configs dynamically
  amis       = yamldecode(file("${path.module}/../../configs/${var.profile}/amis.yaml"))
  networking = yamldecode(file("${path.module}/../../configs/${var.profile}/networking.yaml"))

  # Merge tags for current environment
  merged_tags = merge(
    local.tags.global_tags,
    lookup(local.tags.environment_tags, var.profile, {})
  )
}
