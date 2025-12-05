/**
 * Connectivity Test Module
 *
 * Creates EC2 instances in vpc_a and vpc_b to validate VPC peering connectivity.
 *
 * Test Architecture:
 *   - Bastion (vpc_a public subnet)    - SSH jump host with public IP
 *   - VPC A Private Instance           - Target in same VPC
 *   - VPC B Private Instance           - Target in peered VPC
 *
 * Test Steps:
 *   1. SSH into Bastion (vpc_a public subnet)
 *   2. Run ~/test_connectivity.sh to test all connections
 *   3. Or manually ping each private instance
 *
 * Expected Results:
 *   - Bastion -> VPC A Private: SUCCESS (same VPC)
 *   - Bastion -> VPC B Private: SUCCESS (via VPC peering)
 */

/**
 * Key Pair Module
 *
 * Generates an SSH key pair for EC2 instance access.
 * The private key is output for saving to a local file.
 */
module "key_pair" {
  source = "./key_pair"

  name_suffix = var.name_suffix
}

/**
 * Security Groups Module
 *
 * Creates security groups for test instances in both VPCs.
 * Rules are loaded from YAML configuration files.
 */
module "security_groups" {
  source = "./security_groups"

  vpc_a_id             = var.vpc_a_id
  vpc_b_id             = var.vpc_b_id
  vpc_a_cidr           = var.vpc_a_cidr
  vpc_b_cidr           = var.vpc_b_cidr
  name_suffix          = var.name_suffix
  common_firewall_path = var.common_firewall_path
}

/**
 * Instances Module
 *
 * Creates 3 EC2 instances for connectivity testing:
 *   1. Bastion in vpc_a public subnet (jump host)
 *   2. Target in vpc_a private subnet (same VPC test)
 *   3. Target in vpc_b private subnet (cross-VPC peering test)
 */
module "instances" {
  source = "./instances"

  # EC2 configuration from amis.yaml
  ami_id        = local.ec2_config.amis[var.region]
  instance_type = local.ec2_config.instance_type

  # Subnet IDs
  bastion_subnet_id       = data.aws_subnet.vpc_a_public.id
  vpc_a_private_subnet_id = data.aws_subnet.vpc_a_private.id
  vpc_b_private_subnet_id = data.aws_subnet.vpc_b_private.id

  # Security Group IDs
  bastion_sg_id       = module.security_groups.bastion_sg_id
  vpc_a_private_sg_id = module.security_groups.vpc_a_private_sg_id
  vpc_b_private_sg_id = module.security_groups.vpc_b_private_sg_id

  # SSH access - use provided key or auto-generated key
  key_name    = var.key_name != "" ? var.key_name : module.key_pair.key_name
  name_suffix = var.name_suffix
}
