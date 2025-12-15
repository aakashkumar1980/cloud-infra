/**
 * Input Variables
 *
 * @var vpcs            - Map of VPC configurations. Each VPC has:
 *                        - cidr: IP address range (e.g., "10.0.0.0/24")
 *                        - subnets: List of subnet definitions
 *
 * @var az_names        - List of availability zone names
 *                        (e.g., ["us-east-1a", "us-east-1b"])
 *
 * @var az_letter_to_ix - Maps zone letters to array indices
 *                        (e.g., { a=0, b=1, c=2 })
 *
 * @var tags_common     - Tags applied to all resources
 */
variable "vpcs"            { type = map(any) }
variable "az_names"        { type = list(string) }
variable "az_letter_to_ix" { type = map(number) }
variable "tags_common"     { type = map(string) }
