/**
 * Local Variables
 *
 * Centralizes naming conventions to avoid duplication in child modules.
 *
 * @local name_suffix - Standard suffix for all resource names in this region
 *        Format: {region}-{environment}-{managed_by}
 *        Example: "nvirginia-dev-terraform"
 *
 * Usage:
 *   Instead of each module building its own suffix, they receive name_suffix
 *   and simply append it: "vpc_a-${var.name_suffix}" -> "vpc_a-nvirginia-dev-terraform"
 */
locals {
  name_suffix = "${var.common_tags["region"]}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
}
