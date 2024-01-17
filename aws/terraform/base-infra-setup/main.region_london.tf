module "COMMON-REGION_LONDON" {
  source = "../../terraform"
}


/** NETWORKING */
module "VPC-REGION_LONDON" {
  source = "./networking/vpc"
  providers = {
    aws = aws.region_london
  }

  ns          = module.COMMON-REGION_LONDON.project.namespace
  vpc_flatmap = local.vpc.vpc-region_london
}

module "SUBNETS-REGION_LONDON" {
  source     = "./networking/subnets"
  depends_on = [module.VPC-REGION_LONDON]
  providers = {
    aws = aws.region_london
  }

  vpc             = module.VPC-REGION_LONDON.output-vpc
  subnets_flatmap = local.vpc.subnets-region_london
}

module "ROUTETABLE-REGION_LONDON" {
  source     = "./networking/routetable"
  depends_on = [module.SUBNETS-REGION_LONDON]
  providers = {
    aws = aws.region_london
  }

  vpc     = module.VPC-REGION_LONDON.output-vpc
  igw     = module.VPC-REGION_LONDON.output-igw
  subnets = module.SUBNETS-REGION_LONDON.output-subnets
}

module "NACL-REGION_LONDON" {
  source     = "./networking/security/nacl"
  depends_on = [module.SUBNETS-REGION_LONDON]
  providers = {
    aws = aws.region_london
  }

  vpc               = module.VPC-REGION_LONDON.output-vpc
  subnets           = module.SUBNETS-REGION_LONDON.output-subnets
  ingress-rules_map = concat(local.firewall.ingress.standard_rules, local.firewall.ingress.epidermal_port_rules)
  egress-rules_map  = local.firewall.egress
}

/** EC2 **/
module "SECURITYGROUP-REGION_LONDON" {
  source     = "./security/securitygroup"
  depends_on = [module.VPC-REGION_LONDON]
  providers = {
    aws = aws.region_london
  }

  vpc               = module.VPC-REGION_LONDON.output-vpc
  ingress-rules_map = local.firewall.ingress.standard_rules
}

module "KEYPAIR-REGION_LONDON" {
  source = "../_templates/ec2/security/keypair"
  providers = {
    aws = aws.region_london
  }

  ns          = module.COMMON-REGION_LONDON.project.namespace
  vpc_flatmap = local.vpc.vpc-region_london
}

module "EC2-REGION_LONDON" {
  source     = "./ec2"
  depends_on = [module.ROUTETABLE-REGION_LONDON, module.KEYPAIR-REGION_LONDON]
  providers = {
    aws = aws.region_london
  }

  vpc           = module.VPC-REGION_LONDON.output-vpc
  subnets       = module.SUBNETS-REGION_LONDON.output-subnets
  rt_private    = module.ROUTETABLE-REGION_LONDON.output-rt_private
  keypair       = module.KEYPAIR-REGION_LONDON.output-keypair
  ami           = "ami-00400a198e1509988"
  instance_type = "t3a.nano"

}
