/**
 * Local Variables
 *
 * Loads EC2 AMI configuration and derives subnet Name tags from base_network
 * naming convention.
 *
 * Config files loaded:
 *   - configs/<profile>/amis.yaml -> EC2 AMI and instance type definitions
 *
 * Cross-Region Setup:
 *   - N. Virginia: vpc_a with bastion and private instance
 *   - London: vpc_c with private instance only
 *
 * Pattern: subnet_{tier}_zone_{zone}-{vpc_name}-{name_suffix}
 */
locals {
  # Load AMI configuration from config file
  amis_cfg = yamldecode(file(var.config_path))

  # EC2 configuration for regular instances
  ec2_config = local.amis_cfg.ec2.regular_instance

  # N. Virginia subnet names (vpc_a)
  # vpc_a public subnet in zone a (bastion/jump host)
  vpc_a_public_subnet_name = "subnet_public_zone_a-vpc_a-${var.name_suffix_nvirginia}"

  # vpc_a private subnet in zone a (target instance)
  vpc_a_private_subnet_name = "subnet_private_zone_a-vpc_a-${var.name_suffix_nvirginia}"

  # London subnet name (vpc_c)
  # vpc_c private subnet in zone c (target instance)
  vpc_c_private_subnet_name = "subnet_private_zone_c-vpc_c-${var.name_suffix_london}"
}
