/**
 * Input Variables
 *
 * @var vpcs            - Map of VPC configurations. Each VPC has a CIDR block
 *                        and a list of subnets with their tier (public/private),
 *                        CIDR, and availability zone.
 *
 * @var az_names        - List of availability zone names in the region
 *                        (e.g., ["us-east-1a", "us-east-1b", "us-east-1c"])
 *
 * @var az_letter_to_ix - Maps zone letters to array indices
 *                        (e.g., { a=0, b=1, c=2 })
 *
 * @var common_tags     - Tags applied to all resources
 *                        (e.g., { environment="dev", project="myapp" })
 *
 * @var region          - Region identifier used in resource naming
 *                        (e.g., "nvirginia", "london")
 */
variable "vpcs"            { type = map(any) }
variable "az_names"        { type = list(string) }
variable "az_letter_to_ix" { type = map(number) }
variable "common_tags"     { type = map(string) }
variable "region"          { type = string }
