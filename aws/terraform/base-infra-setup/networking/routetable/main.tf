module "ROUTETABLE_GENERIC" {
  source = "./routetable_generic"

  vpc     = var.vpc
  igw     = var.igw
  subnets = var.subnets
}
module "ROUTETABLE_PUBLIC" {
  source = "./routetable_public"

  vpc     = var.vpc
  igw     = var.igw
  subnets = var.subnets
}

module "ROUTETABLE_PRIVATE" {
  source = "./routetable_private"

  vpc     = var.vpc
  subnets = var.subnets
}

