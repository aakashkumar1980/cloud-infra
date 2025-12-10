/**
 * Data Sources - Reference Existing Infrastructure
 *
 * IMPORTANT: This module depends on the following being deployed FIRST:
 *   1. aws/base_network                                    - VPCs, Subnets, NAT, IGW
 *   2. aws/_learnings/vpc_connectivity/01_vpc_peering/01_same_region     - VPC A ↔ B peering
 *   3. aws/_learnings/vpc_connectivity/01_vpc_peering/02_different_region - N.Virginia ↔ London peering
 *
 * If any of these are not deployed, Terraform will fail with "resource not found" errors.
 *
 * Execution Order:
 *   cd aws/base_network && terraform apply
 *   cd aws/_learnings/vpc_connectivity/01_vpc_peering/01_same_region && terraform apply
 *   cd aws/_learnings/vpc_connectivity/01_vpc_peering/02_different_region && terraform apply
 *   cd aws/_learnings/_aaditya_designers_corp/01_infra_setup && terraform apply
 */

# =============================================================================
# N. VIRGINIA REGION (us-east-1) - VPC A (AD Server)
# =============================================================================

# -----------------------------------------------------------------------------
# VPC A - For AD DS Server
# -----------------------------------------------------------------------------
data "aws_vpc" "vpc_a" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = [local.vpc_a_name]
  }
}

# -----------------------------------------------------------------------------
# VPC A - Private Subnet (for AD Server)
# -----------------------------------------------------------------------------
data "aws_subnet" "vpc_a_private" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = ["subnet_private_zone_a-${local.vpc_a_name}"]
  }
}

# -----------------------------------------------------------------------------
# VPC A - Public Subnet (for potential bastion/NAT)
# -----------------------------------------------------------------------------
data "aws_subnet" "vpc_a_public" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = ["subnet_public_zone_a-${local.vpc_a_name}"]
  }
}

# =============================================================================
# LONDON REGION (eu-west-2) - VPC C (App Servers)
# =============================================================================

# -----------------------------------------------------------------------------
# VPC C - For Application Servers (GitLab, Wiki.js, Keycloak, Syncope)
# -----------------------------------------------------------------------------
data "aws_vpc" "vpc_c" {
  provider = aws.london

  filter {
    name   = "tag:Name"
    values = [local.vpc_c_name]
  }
}

# -----------------------------------------------------------------------------
# VPC C - Private Subnet (for App Servers)
# -----------------------------------------------------------------------------
data "aws_subnet" "vpc_c_private" {
  provider = aws.london

  filter {
    name   = "tag:Name"
    values = ["subnet_private_zone_c-${local.vpc_c_name}"]
  }
}

# -----------------------------------------------------------------------------
# VPC C - Public Subnet (for potential ALB)
# -----------------------------------------------------------------------------
data "aws_subnet" "vpc_c_public" {
  provider = aws.london

  filter {
    name   = "tag:Name"
    values = ["subnet_public_zone_c-${local.vpc_c_name}"]
  }
}

# =============================================================================
# VPC PEERING CONNECTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Cross-Region Peering: N. Virginia (VPC A) ↔ London (VPC C)
# This is used by Security Groups to allow traffic between regions
# -----------------------------------------------------------------------------
data "aws_vpc_peering_connection" "nvirginia_to_london" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = ["peering-vpc_a-to-vpc_c-${local.REGION_N_VIRGINIA}-to-${local.REGION_LONDON}-${var.profile}-terraform"]
  }

  filter {
    name   = "status-code"
    values = ["active"]
  }
}
