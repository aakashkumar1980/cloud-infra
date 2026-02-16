/**
 * Local Variables
 *
 * Loads EC2 AMI configuration and derives subnet Name tags from base_network
 * naming convention.
 *
 * Config files loaded:
 *   - configs/<profile>/amis.yaml -> EC2 AMI and instance type definitions
 *
 * Pattern: subnet_{tier}_zone_{zone}-{vpc_name}-{name_suffix}
 */
locals {
  # Load AMI configuration from config file
  amis_cfg = yamldecode(file(var.config_path))

  # EC2 configuration for regular instances
  ec2_config = local.amis_cfg.ec2.regular_instance

  # Derive subnet Name tags using base_network naming convention
  # vpc_a public subnet in zone a (bastion/jump host)
  vpc_a_public_subnet_name = "subnet_public_zone_a-vpc_a-${var.name_suffix}"

  # vpc_a private subnet in zone a (target instance)
  vpc_a_private_subnet_name = "subnet_private_zone_a-vpc_a-${var.name_suffix}"

  # vpc_b private subnet in zone b (target instance)
  vpc_b_private_subnet_name = "subnet_private_zone_b-vpc_b-${var.name_suffix}"
}
