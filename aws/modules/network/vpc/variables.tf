/**
 * A single-VPC builder. Creates:
 * - VPC with DNS enabled
 * - Subnets from provided map (typed as public/private/generic)
 * - IGW + public route table
 * - NAT (single or per-AZ) + private route table(s)
 * - Route table associations for public/private subnets
 */
variable "region"  { type = string }

variable "name" {
  description = "Logical VPC name (map key from region module)"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR"
  type        = string
}

/**
 * Subnets defined as a map:
 *   key: arbitrary label ("1","2","3"...)
 *   value: { type, cidr_block, availability_zone_index }
 */
variable "subnets" {
  description = "Map of subnet definitions by key"
  type = map(object({
    type                    = string       # public | private | generic
    cidr_block              = string
    availability_zone_index = string       # letter: a,b,c,d...
  }))
}

/** Cost toggle */
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
