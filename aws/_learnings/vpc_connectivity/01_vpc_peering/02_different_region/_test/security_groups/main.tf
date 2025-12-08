/**
 * Security Groups Module - Cross-Region
 *
 * Creates security groups for test instances in vpc_a (N. Virginia) and vpc_c (London).
 * Rules are loaded from YAML configuration files:
 *   - Common rules: aws/configs/firewall.yaml
 *   - Custom rules: ./firewall.yaml
 *
 * Architecture:
 *   Bastion (vpc_a public, N. Virginia):
 *     - All ingress (for testing purposes)
 *     - All outbound
 *
 *   VPC A Private Instance (N. Virginia):
 *     - SSH from vpc_a (from bastion)
 *     - ICMP from vpc_a (from bastion)
 *     - ICMP from vpc_c (for cross-region testing)
 *     - All outbound
 *
 *   VPC C Private Instance (London):
 *     - SSH from vpc_a via peering (from bastion)
 *     - ICMP from vpc_a via peering
 *     - All outbound
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
 * Security Group for Bastion Instance (vpc_a public subnet, N. Virginia)
 *
 * Jump host for SSH access and connectivity testing.
 * Uses all_traffic rule from common firewall config for testing purposes.
 */
resource "aws_security_group" "sg_bastion" {
  provider = aws.nvirginia

  name        = "test_sg_bastion-${var.name_suffix_nvirginia}"
  description = "Security group for bastion/jump host in vpc_a public subnet (N. Virginia)"
  vpc_id      = var.vpc_a_id

  tags = {
    Name = "test_sg_bastion-vpc-a-public-${var.name_suffix_nvirginia}"
  }
}

# Bastion ingress - All traffic (from common firewall.yaml)
resource "aws_vpc_security_group_ingress_rule" "bastion_all_ingress" {
  provider = aws.nvirginia
  for_each = { for idx, rule in local.common_firewall.ingress.all_traffic : idx => rule }

  security_group_id = aws_security_group.sg_bastion.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

# Bastion egress - All outbound (from custom firewall.yaml)
resource "aws_vpc_security_group_egress_rule" "bastion_all_egress" {
  provider = aws.nvirginia
  for_each = { for idx, rule in local.custom_firewall.bastion.egress : idx => rule }

  security_group_id = aws_security_group.sg_bastion.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

/**
 * Security Group for VPC A Private Instance (N. Virginia)
 *
 * Target instance in vpc_a private subnet.
 */
resource "aws_security_group" "sg_vpc_a_private" {
  provider = aws.nvirginia

  name        = "test_sg_vpc_a_private-${var.name_suffix_nvirginia}"
  description = "Security group for test instance in vpc_a private subnet (N. Virginia)"
  vpc_id      = var.vpc_a_id

  tags = {
    Name = "test_sg-vpc-a-private-${var.name_suffix_nvirginia}"
  }
}

# VPC A Private - SSH from vpc_a (dynamic CIDR) - for bastion access
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_ssh_from_vpc_a" {
  provider = aws.nvirginia

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[0].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[0].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[0].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[0].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC A Private - ICMP from vpc_a (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_icmp_from_vpc_a" {
  provider = aws.nvirginia

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[1].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[1].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[1].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[1].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC A Private - ICMP from vpc_c (dynamic CIDR) - cross-region
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_icmp_from_vpc_c" {
  provider = aws.nvirginia

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[2].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[2].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[2].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[2].to_port
  cidr_ipv4         = var.vpc_c_cidr # Dynamic CIDR
}

# VPC A Private - iperf3 from vpc_a (dynamic CIDR) - for bandwidth testing
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_iperf3_from_vpc_a" {
  provider = aws.nvirginia

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[3].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[3].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[3].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[3].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC A Private - All egress
resource "aws_vpc_security_group_egress_rule" "vpc_a_private_all_egress" {
  provider = aws.nvirginia
  for_each = { for idx, rule in local.custom_firewall.vpc_a_private.egress : idx => rule }

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

/**
 * Security Group for VPC C Private Instance (London)
 *
 * Target instance in vpc_c private subnet (cross-region target).
 */
resource "aws_security_group" "sg_vpc_c_private" {
  provider = aws.london

  name        = "test_sg_vpc_c_private-${var.name_suffix_london}"
  description = "Security group for test instance in vpc_c private subnet (London)"
  vpc_id      = var.vpc_c_id

  tags = {
    Name = "test_sg-vpc-c-private-${var.name_suffix_london}"
  }
}

# VPC C Private - SSH from vpc_a via cross-region peering (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_c_private_ssh_from_vpc_a" {
  provider = aws.london

  security_group_id = aws_security_group.sg_vpc_c_private.id
  description       = local.custom_firewall.vpc_c_private.ingress[0].description
  ip_protocol       = local.custom_firewall.vpc_c_private.ingress[0].protocol
  from_port         = local.custom_firewall.vpc_c_private.ingress[0].from_port
  to_port           = local.custom_firewall.vpc_c_private.ingress[0].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC C Private - ICMP from vpc_a via cross-region peering (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_c_private_icmp_from_vpc_a" {
  provider = aws.london

  security_group_id = aws_security_group.sg_vpc_c_private.id
  description       = local.custom_firewall.vpc_c_private.ingress[1].description
  ip_protocol       = local.custom_firewall.vpc_c_private.ingress[1].protocol
  from_port         = local.custom_firewall.vpc_c_private.ingress[1].from_port
  to_port           = local.custom_firewall.vpc_c_private.ingress[1].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC C Private - iperf3 from vpc_a via cross-region peering (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_c_private_iperf3_from_vpc_a" {
  provider = aws.london

  security_group_id = aws_security_group.sg_vpc_c_private.id
  description       = local.custom_firewall.vpc_c_private.ingress[2].description
  ip_protocol       = local.custom_firewall.vpc_c_private.ingress[2].protocol
  from_port         = local.custom_firewall.vpc_c_private.ingress[2].from_port
  to_port           = local.custom_firewall.vpc_c_private.ingress[2].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC C Private - All egress
resource "aws_vpc_security_group_egress_rule" "vpc_c_private_all_egress" {
  provider = aws.london
  for_each = { for idx, rule in local.custom_firewall.vpc_c_private.egress : idx => rule }

  security_group_id = aws_security_group.sg_vpc_c_private.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}
