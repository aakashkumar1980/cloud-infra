/**
 * Region-scoped “orchestrator” module.
 * It fans out one child VPC module per entry in var.vpcs using module for_each.
 */
variable "project" { type = string }
variable "env"     { type = string }
variable "owner"   { type = string }
variable "region"  { type = string }

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

variable "extra_tags" {
  description = "Extra tags to merge into all resources"
  type        = map(string)
  default     = {}
}
