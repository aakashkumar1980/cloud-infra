/**
 * Connectivity Test Module
 *
 * Creates EC2 instances in vpc_a and vpc_b to validate VPC peering connectivity.
 *
 * Test Steps:
 *   1. SSH into Test Instance A (vpc_a, public subnet)
 *   2. Ping Test Instance B (vpc_b, private subnet) using private IP
 *   3. If ping succeeds, VPC peering is working correctly
 */

/**
 * Security Groups Module
 *
 * Creates security groups for test instances in both VPCs.
 */
module "security_groups" {
  source = "./security_groups"

  vpc_a_id    = var.vpc_a_id
  vpc_b_id    = var.vpc_b_id
  vpc_a_cidr  = var.vpc_a_cidr
  vpc_b_cidr  = var.vpc_b_cidr
  my_ip       = var.my_ip
  name_suffix = var.name_suffix
}

/**
 * Instances Module
 *
 * Creates EC2 instances for connectivity testing.
 */
module "instances" {
  source = "./instances"

  ami_id               = data.aws_ami.amazon_linux.id
  instance_a_subnet_id = data.aws_subnet.vpc_a_public.id
  instance_b_subnet_id = data.aws_subnet.vpc_b_private.id
  instance_a_sg_id     = module.security_groups.instance_a_sg_id
  instance_b_sg_id     = module.security_groups.instance_b_sg_id
  key_name             = var.key_name
  name_suffix          = var.name_suffix
}
