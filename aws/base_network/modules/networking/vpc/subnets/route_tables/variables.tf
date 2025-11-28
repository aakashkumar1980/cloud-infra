# VPC configurations
variable "vpcs" { type = map(any) }

# Map of VPC names to VPC IDs
variable "vpc_ids" { type = map(string) }

# Map of VPC names to Internet Gateway IDs (for public subnets)
variable "igw_ids" { type = map(string) }

# Map of VPC names to NAT Gateway IDs (for private subnets)
variable "nat_gateway_ids" { type = map(string) }

# Map of subnet keys to subnet IDs
variable "subnet_ids" { type = map(string) }

# Tags to apply to all resources
variable "common_tags" { type = map(string) }

# Region identifier for naming (e.g., "nvirginia")
variable "region" { type = string }
