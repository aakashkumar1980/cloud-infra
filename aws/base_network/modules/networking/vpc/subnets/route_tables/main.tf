# Route Tables Module
# Manages routing for public subnets (via IGW) and private subnets (via NAT GW)

# Public subnets: 0.0.0.0/0 -> Internet Gateway
module "route_tables_public" {
  source      = "./public"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  igw_ids     = var.igw_ids
  subnet_ids  = var.subnet_ids
  common_tags = var.common_tags
  region      = var.region
}

# Private subnets: 0.0.0.0/0 -> NAT Gateway
module "route_tables_private" {
  source          = "./private"
  vpcs            = var.vpcs
  vpc_ids         = var.vpc_ids
  nat_gateway_ids = var.nat_gateway_ids
  subnet_ids      = var.subnet_ids
  common_tags     = var.common_tags
  region          = var.region
}
