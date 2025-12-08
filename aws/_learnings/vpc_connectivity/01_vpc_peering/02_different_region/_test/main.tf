/**
 * Connectivity Test Module - Cross-Region
 *
 * Creates EC2 instances in vpc_a (N. Virginia) and vpc_c (London)
 * to validate cross-region VPC peering connectivity.
 *
 * Test Architecture:
 *   - Bastion (vpc_a public subnet, N. Virginia) - SSH jump host with public IP
 *   - VPC A Private Instance (N. Virginia)       - Target in same VPC
 *   - VPC C Private Instance (London)            - Target in peered VPC (different region)
 *
 * Test Steps:
 *   1. SSH into Bastion (vpc_a public subnet in N. Virginia)
 *   2. Run ~/test_connectivity.sh to test all connections
 *   3. Or manually ping each private instance
 *
 * Expected Results:
 *   - Bastion -> VPC A Private: SUCCESS (same VPC, same region)
 *   - Bastion -> VPC C Private: SUCCESS (via cross-region VPC peering)
 *
 * Cross-Region Considerations:
 *   - Higher latency expected for cross-region traffic (~60-100ms)
 *   - Each region uses different AMI IDs
 *   - Key pairs are created in each region separately
 */

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.nvirginia, aws.london]
    }
  }
}

/**
 * Key Pair Module - N. Virginia
 *
 * Generates an SSH key pair for EC2 instance access in N. Virginia.
 * The same key will also be registered in London for cross-region access.
 */
module "key_pair_nvirginia" {
  source = "./key_pair"

  providers = {
    aws = aws.nvirginia
  }

  name_suffix = var.name_suffix_nvirginia
}

/**
 * Key Pair Module - London
 *
 * Registers the same public key in London region.
 * This allows SSH access to VPC C instances using the same private key.
 */
module "key_pair_london" {
  source = "./key_pair"

  providers = {
    aws = aws.london
  }

  name_suffix       = var.name_suffix_london
  public_key_openssh = module.key_pair_nvirginia.public_key_openssh
}

/**
 * Security Groups Module
 *
 * Creates security groups for test instances in both VPCs.
 * Rules are loaded from YAML configuration files.
 */
module "security_groups" {
  source = "./security_groups"

  providers = {
    aws.nvirginia = aws.nvirginia
    aws.london    = aws.london
  }

  vpc_a_id             = var.vpc_a_id
  vpc_c_id             = var.vpc_c_id
  vpc_a_cidr           = var.vpc_a_cidr
  vpc_c_cidr           = var.vpc_c_cidr
  name_suffix_nvirginia = var.name_suffix_nvirginia
  name_suffix_london    = var.name_suffix_london
  common_firewall_path = var.common_firewall_path
}

/**
 * Instances Module
 *
 * Creates 3 EC2 instances for connectivity testing:
 *   1. Bastion in vpc_a public subnet (jump host) - N. Virginia
 *   2. Target in vpc_a private subnet (same VPC test) - N. Virginia
 *   3. Target in vpc_c private subnet (cross-region peering test) - London
 */
module "instances" {
  source = "./instances"

  providers = {
    aws.nvirginia = aws.nvirginia
    aws.london    = aws.london
  }

  # EC2 configuration from amis.yaml
  ami_id_nvirginia = local.ec2_config.amis["nvirginia"]
  ami_id_london    = local.ec2_config.amis["london"]
  instance_type    = local.ec2_config.instance_type

  # Subnet IDs
  bastion_subnet_id       = data.aws_subnet.vpc_a_public.id
  vpc_a_private_subnet_id = data.aws_subnet.vpc_a_private.id
  vpc_c_private_subnet_id = data.aws_subnet.vpc_c_private.id

  # Security Group IDs
  bastion_sg_id       = module.security_groups.bastion_sg_id
  vpc_a_private_sg_id = module.security_groups.vpc_a_private_sg_id
  vpc_c_private_sg_id = module.security_groups.vpc_c_private_sg_id

  # SSH access - use auto-generated key and copy to bastion for private instance access
  key_name_nvirginia = module.key_pair_nvirginia.key_name
  key_name_london    = module.key_pair_london.key_name
  private_key_pem    = module.key_pair_nvirginia.private_key_pem
  name_suffix_nvirginia = var.name_suffix_nvirginia
  name_suffix_london    = var.name_suffix_london
}
