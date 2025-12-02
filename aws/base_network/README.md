# AWS Base Network Module

This Terraform module creates the foundational networking infrastructure for AWS deployments across multiple regions (N. Virginia `us-east-1` and London `eu-west-2`).

## Architecture Overview

The module provisions a complete VPC networking stack including:
- Virtual Private Clouds (VPCs) with custom CIDR blocks
- Public and Private Subnets across multiple availability zones
- Internet Gateways for public internet access
- NAT Gateways for private subnet outbound access
- Route Tables for traffic routing

## AWS Components Pricing

| Component | Terraform Resource | Pricing Model | Cost Details |
|-----------|-------------------|---------------|--------------|
| **VPC** | `aws_vpc` | Free | No charge for VPC itself |
| **Subnet** | `aws_subnet` | Free | No charge for subnets |
| **Internet Gateway** | `aws_internet_gateway` | Free | No hourly or data charges |
| **Route Table** | `aws_route_table` | Free | No charge for route tables |
| **Route** | `aws_route` | Free | No charge for routes |
| **Route Table Association** | `aws_route_table_association` | Free | No charge for associations |
| **Elastic IP** | `aws_eip` | Hourly | $0.005/hour (~$3.60/month) when allocated but not associated with running instance |
| **NAT Gateway** | `aws_nat_gateway` | Hourly + Data | $0.045/hour (~$32.40/month) + $0.045/GB data processed |

> **Note**: Prices shown are for `us-east-1` region. Other regions may vary. Refer to [AWS VPC Pricing](https://aws.amazon.com/vpc/pricing/) for current rates.

## Cost Estimation

### Fixed Monthly Costs (per NAT Gateway)

| Item | Calculation | Monthly Cost |
|------|-------------|--------------|
| NAT Gateway | $0.045 × 730 hours | ~$32.85 |
| Elastic IP (associated) | Free when attached to NAT GW | $0.00 |
| **Subtotal per NAT GW** | | **~$32.85** |

### Variable Costs

| Item | Rate | Notes |
|------|------|-------|
| NAT Gateway Data Processing | $0.045/GB | Charged for all data processed through NAT GW |
| Data Transfer Out | $0.09/GB | First 10TB/month (standard AWS data transfer) |

### Example: Single VPC with NAT Gateway

For a VPC with one NAT Gateway processing 100GB/month:
- NAT Gateway hourly: ~$32.85
- Data processing: 100GB × $0.045 = $4.50
- **Total: ~$37.35/month**

## Module Structure

```
base_network/
├── main.tf                    # VPC module instantiation for each region
├── variables.tf               # Input variables (profile)
├── locals.tf                  # Configuration loading and transformations
├── data.tf                    # Data sources (availability zones)
├── outputs.tf                 # Module outputs
├── providers.tf               # AWS provider configurations
└── modules/
    └── vpc/
        ├── main.tf            # VPC and orchestration
        ├── internet_gateway/  # Internet Gateway resources
        └── subnets/
            ├── main.tf        # Subnet resources
            └── route_tables/
                ├── public/    # Public route tables (IGW routing)
                └── private/   # Private route tables + NAT Gateway
```

## Usage

```hcl
terraform init
terraform plan -var="profile=dev"
terraform apply -var="profile=dev"
```

## Cost Optimization Tips

1. **NAT Gateway**: Consider using a single NAT Gateway per VPC instead of per-AZ for non-production environments to reduce costs
2. **NAT Instance**: For low-traffic workloads, consider using a NAT Instance (EC2) instead of NAT Gateway
3. **VPC Endpoints**: Use Gateway VPC Endpoints (free) for S3 and DynamoDB to reduce NAT Gateway data processing charges
4. **Private Subnets**: Only provision private subnets with NAT Gateway access when outbound internet is required
