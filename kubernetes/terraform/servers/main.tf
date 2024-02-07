module "EC2" {
  source = "./ec2"

  ns      = var.ns
  base_ns = var.base_ns

  servers              = local.servers
  vpc_a                = var.vpc_a
  vpc_b                = var.vpc_b
  vpc_a-subnet_private = var.vpc_a-subnet_private
  vpc_b-subnet_private = var.vpc_b-subnet_private
  vpc_a-sg_private     = var.vpc_a-sg_private
  vpc_b-sg_private     = var.vpc_b-sg_private

  ami       = var.ami
  keypair   = var.keypair
  user_data = var.user_data

}
/**
module "EFS" {
  source = "./efs"

  ns      = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  base_ns = module.COMMON-BASE_INFRA_SETUP.project.namespace

  servers              = local.servers
  vpc_a                = data.aws_vpc.vpc_a
  vpc_b                = data.aws_vpc.vpc_b
  vpc_a-subnet_private = data.aws_subnet.vpc_a-subnet_private
}
**/
