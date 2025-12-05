/**
 * Security Groups Module
 *
 * Creates security groups for test instances in vpc_a and vpc_b.
 * Rules are loaded from YAML configuration files:
 *   - Common rules: aws/configs/firewall.yaml
 *   - Custom rules: ./firewall.yaml
 *
 * Architecture:
 *   Bastion (vpc_a public):
 *     - All ingress (for testing purposes)
 *     - All outbound
 *
 *   VPC A Private Instance:
 *     - ICMP from vpc_a (from bastion)
 *     - ICMP from vpc_b (for cross-VPC testing)
 *     - All outbound
 *
 *   VPC B Private Instance:
 *     - ICMP from vpc_a (from bastion via peering)
 *     - All outbound
 */

locals {
  # Load firewall configurations
  common_firewall = yamldecode(file(var.common_firewall_path))
  custom_firewall = yamldecode(file("${path.module}/firewall.yaml"))
}

/**
 * Security Group for Bastion Instance (vpc_a public subnet)
 *
 * Jump host for SSH access and connectivity testing.
 * Uses all_traffic rule from common firewall config for testing purposes.
 */
resource "aws_security_group" "sg_bastion" {
  name        = "test_sg_bastion-${var.name_suffix}"
  description = "Security group for bastion/jump host in vpc_a public subnet"
  vpc_id      = var.vpc_a_id

  tags = {
    Name = "test_sg-bastion-${var.name_suffix}"
  }
}

# Bastion ingress - All traffic (from common firewall.yaml)
# Note: When protocol is "-1" (all), from_port and to_port must not be specified
resource "aws_vpc_security_group_ingress_rule" "bastion_all_ingress" {
  for_each = { for idx, rule in local.common_firewall.ingress.all_traffic : idx => rule }

  security_group_id = aws_security_group.sg_bastion.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

# Bastion egress - All outbound (from custom firewall.yaml)
# Note: When protocol is "-1" (all), from_port and to_port must not be specified
resource "aws_vpc_security_group_egress_rule" "bastion_all_egress" {
  for_each = { for idx, rule in local.custom_firewall.bastion.egress : idx => rule }

  security_group_id = aws_security_group.sg_bastion.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

/**
 * Security Group for VPC A Private Instance
 *
 * Target instance in vpc_a private subnet.
 */
resource "aws_security_group" "sg_vpc_a_private" {
  name        = "test_sg_vpc_a_private-${var.name_suffix}"
  description = "Security group for test instance in vpc_a private subnet"
  vpc_id      = var.vpc_a_id

  tags = {
    Name = "test_sg-vpc-a-private-${var.name_suffix}"
  }
}

# VPC A Private - ICMP from vpc_a (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_icmp_from_vpc_a" {
  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[0].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[0].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[0].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[0].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC A Private - ICMP from vpc_b (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_icmp_from_vpc_b" {
  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[1].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[1].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[1].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[1].to_port
  cidr_ipv4         = var.vpc_b_cidr # Dynamic CIDR
}

# VPC A Private - iperf3 from vpc_a (dynamic CIDR) - for bandwidth testing
resource "aws_vpc_security_group_ingress_rule" "vpc_a_private_iperf3_from_vpc_a" {
  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = local.custom_firewall.vpc_a_private.ingress[2].description
  ip_protocol       = local.custom_firewall.vpc_a_private.ingress[2].protocol
  from_port         = local.custom_firewall.vpc_a_private.ingress[2].from_port
  to_port           = local.custom_firewall.vpc_a_private.ingress[2].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC A Private - All egress
# Note: When protocol is "-1" (all), from_port and to_port must not be specified
resource "aws_vpc_security_group_egress_rule" "vpc_a_private_all_egress" {
  for_each = { for idx, rule in local.custom_firewall.vpc_a_private.egress : idx => rule }

  security_group_id = aws_security_group.sg_vpc_a_private.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}

/**
 * Security Group for VPC B Private Instance
 *
 * Target instance in vpc_b private subnet (cross-VPC target).
 */
resource "aws_security_group" "sg_vpc_b_private" {
  name        = "test_sg_vpc_b_private-${var.name_suffix}"
  description = "Security group for test instance in vpc_b private subnet"
  vpc_id      = var.vpc_b_id

  tags = {
    Name = "test_sg-vpc-b-private-${var.name_suffix}"
  }
}

# VPC B Private - ICMP from vpc_a via peering (dynamic CIDR)
resource "aws_vpc_security_group_ingress_rule" "vpc_b_private_icmp_from_vpc_a" {
  security_group_id = aws_security_group.sg_vpc_b_private.id
  description       = local.custom_firewall.vpc_b_private.ingress[0].description
  ip_protocol       = local.custom_firewall.vpc_b_private.ingress[0].protocol
  from_port         = local.custom_firewall.vpc_b_private.ingress[0].from_port
  to_port           = local.custom_firewall.vpc_b_private.ingress[0].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC B Private - iperf3 from vpc_a via peering (dynamic CIDR) - for bandwidth testing
resource "aws_vpc_security_group_ingress_rule" "vpc_b_private_iperf3_from_vpc_a" {
  security_group_id = aws_security_group.sg_vpc_b_private.id
  description       = local.custom_firewall.vpc_b_private.ingress[1].description
  ip_protocol       = local.custom_firewall.vpc_b_private.ingress[1].protocol
  from_port         = local.custom_firewall.vpc_b_private.ingress[1].from_port
  to_port           = local.custom_firewall.vpc_b_private.ingress[1].to_port
  cidr_ipv4         = var.vpc_a_cidr # Dynamic CIDR
}

# VPC B Private - All egress
# Note: When protocol is "-1" (all), from_port and to_port must not be specified
resource "aws_vpc_security_group_egress_rule" "vpc_b_private_all_egress" {
  for_each = { for idx, rule in local.custom_firewall.vpc_b_private.egress : idx => rule }

  security_group_id = aws_security_group.sg_vpc_b_private.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.protocol == "-1" ? null : try(each.value.from_port, null)
  to_port           = each.value.protocol == "-1" ? null : try(each.value.to_port, null)
  cidr_ipv4         = each.value.cidr_ipv4
}
