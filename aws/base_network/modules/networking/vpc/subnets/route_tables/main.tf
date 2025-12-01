/**
 * Route Tables Module
 *
 * Controls how network traffic flows within and outside of subnets.
 * Route tables are like road signs that tell traffic where to go.
 *
 * This module creates two types of route tables:
 *
 *   Public Route Tables:
 *     - For subnets that need direct internet access
 *     - Routes 0.0.0.0/0 (all internet traffic) to Internet Gateway
 *     - Resources get public IPs and can be accessed from internet
 *
 *   Private Route Tables:
 *     - For subnets that need outbound-only internet access
 *     - Routes 0.0.0.0/0 to NAT Gateway
 *     - Resources can reach internet but cannot be reached from internet
 *
 * Traffic Flow:
 *   Public:  Instance -> Route Table -> Internet Gateway -> Internet
 *   Private: Instance -> Route Table -> NAT Gateway -> Internet Gateway -> Internet
 *
 * @module route_tables_public  - Handles public subnet routing via Internet Gateway
 * @module route_tables_private - Handles private subnet routing via NAT Gateway
 */

/** Public subnets: 0.0.0.0/0 -> Internet Gateway */
module "route_tables_public" {
  source            = "./public"
  vpcs              = var.vpcs
  vpc_ids           = var.vpc_ids
  igw_ids           = var.igw_ids
  public_subnet_ids = var.public_subnet_ids
  common_tags       = var.common_tags
  name_suffix       = var.name_suffix
}

/** Private subnets: 0.0.0.0/0 -> NAT Gateway */
module "route_tables_private" {
  source             = "./private"
  vpcs               = var.vpcs
  vpc_ids            = var.vpc_ids
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  igw_ids            = var.igw_ids
  igw_names          = var.igw_names
  common_tags        = var.common_tags
  name_suffix        = var.name_suffix
}
