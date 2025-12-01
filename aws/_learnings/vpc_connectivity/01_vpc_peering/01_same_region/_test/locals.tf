/**
 * Local Variables
 *
 * Derives subnet Name tags from base_network naming convention.
 * Pattern: subnet_{tier}_zone_{zone}-{vpc_name}-{name_suffix}
 */
locals {
  # Derive subnet Name tags using base_network naming convention
  # vpc_a has public subnet in zone a
  vpc_a_public_subnet_name = "subnet_public_zone_a-vpc_a-${var.name_suffix}"

  # vpc_b has private subnet in zone b
  vpc_b_private_subnet_name = "subnet_private_zone_b-vpc_b-${var.name_suffix}"
}
