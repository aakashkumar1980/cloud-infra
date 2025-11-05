/**
 * AWS region to build VPCs in
 */
variable "region"  {
  description = "AWS region to build VPCs in"
  type        = string
}
/**
 * Map of VPC definitions. Each value has:
 *   - cidr_block (string)
 *   - subnets (map of objects):
 *       - type: "public" | "private" | "generic"
 *       - cidr_block: string
 *       - availability_zone_index: "a" | "b" | "c" | "d" ...
 */
variable "vpcs" {
  description = "Map of VPCs defined in JSON"
  type = map(object({
    cidr_block = string
    subnets    = map(object({
      type                     = string
      cidr_block               = string
      availability_zone_index  = string
    }))
  }))
}

variable "single_nat_gateway" {
  description = "true => single NAT per VPC; false => NAT per AZ"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to merge into all resources"
  type        = map(string)
  default     = {}
}
