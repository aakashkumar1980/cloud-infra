/** TODO: Implement later if required in active-standby mode
module "EFS" {
  source = "./efs"

  ns      = var.ns
  base_ns = var.base_ns

  servers              = local.servers
  vpc_a                = var.vpc_a
  vpc_b                = var.vpc_b
  vpc_a-subnet_private = var.vpc_a-subnet_private
}
**/

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

#  efs             = local.efs
#  efs-output-sg   = module.EFS.output-sg

  ami           = var.ami
  keypair       = var.keypair
  user_data_ssm = var.user_data_ssm

}



