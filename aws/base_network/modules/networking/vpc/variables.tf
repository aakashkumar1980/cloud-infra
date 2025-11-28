# VPC configurations with CIDR blocks and subnet definitions
variable "vpcs" { type = map(any) }

# List of availability zone names (e.g., ["us-east-1a", "us-east-1b"])
variable "az_names" { type = list(string) }

# Maps zone letters to indices (e.g., { a=0, b=1, c=2 })
variable "az_letter_to_ix" { type = map(number) }

# Tags to apply to all resources
variable "common_tags" { type = map(string) }

# Region identifier for naming (e.g., "nvirginia")
variable "region" { type = string }
