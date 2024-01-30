module "COMMON-REGION_NVIRGINIA" {
  source = "../../terraform"
}


/** NETWORKING */
module "VPC-REGION_NVIRGINIA" {
  source = "./networking/vpc"
  providers = {
    aws = aws.region_nvirginia
  }

  ns          = module.COMMON-REGION_NVIRGINIA.project.namespace
  vpc_flatmap = local.vpc.vpc-region_nvirginia
}
module "SUBNETS-REGION_NVIRGINIA" {
  source = "./networking/subnets"
  #depends_on = [module.VPC-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc             = module.VPC-REGION_NVIRGINIA.output-vpc
  subnets_flatmap = local.vpc.subnets-region_nvirginia
}

module "ROUTETABLE-REGION_NVIRGINIA" {
  source = "./networking/routetable"
  #depends_on = [module.SUBNETS-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc     = module.VPC-REGION_NVIRGINIA.output-vpc
  igw     = module.VPC-REGION_NVIRGINIA.output-igw
  subnets = module.SUBNETS-REGION_NVIRGINIA.output-subnets
}
module "NACL-REGION_NVIRGINIA" {
  source = "./networking/security/nacl"
  #depends_on = [module.SUBNETS-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc               = module.VPC-REGION_NVIRGINIA.output-vpc
  subnets           = module.SUBNETS-REGION_NVIRGINIA.output-subnets
  ingress-rules_map = concat(local.firewall.ingress.standard_rules, local.firewall.ingress.epidermal_port_rules)
  egress-rules_map  = local.firewall.egress
}

module "SECURITYGROUP-REGION_NVIRGINIA" {
  source = "./security/securitygroup"
  #depends_on = [module.VPC-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc               = module.VPC-REGION_NVIRGINIA.output-vpc
  ingress-rules_map = concat(local.firewall.ingress.standard_rules, local.firewall.ingress.epidermal_port_rules)
}


/** EC2 */
module "KEYPAIR-REGION_NVIRGINIA" {
  source = "../_templates/ec2/security/keypair"
  providers = {
    aws = aws.region_nvirginia
  }

  ns          = module.COMMON-REGION_NVIRGINIA.project.namespace
  vpc_flatmap = local.vpc.vpc-region_nvirginia
}

module "EC2-REGION_NVIRGINIA" {
  source     = "./ec2"
  depends_on = [module.ROUTETABLE-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc           = module.VPC-REGION_NVIRGINIA.output-vpc
  subnets       = module.SUBNETS-REGION_NVIRGINIA.output-subnets
  rt_private    = module.ROUTETABLE-REGION_NVIRGINIA.output-rt_private
  keypair       = module.KEYPAIR-REGION_NVIRGINIA.output-keypair
  ami           = module.COMMON-REGION_NVIRGINIA.project.ec2.nat_instance.region_nvirginia.ami
  instance_type = module.COMMON-REGION_NVIRGINIA.project.ec2.nat_instance.instance_type
}
