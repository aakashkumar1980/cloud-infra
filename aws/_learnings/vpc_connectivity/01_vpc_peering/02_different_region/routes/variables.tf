/**
 * Routes Module - Variables (Cross-Region)
 */

variable "vpc_a_cidr" {
  type        = string
  description = "CIDR block of vpc_a (N. Virginia)"
}

variable "vpc_c_cidr" {
  type        = string
  description = "CIDR block of vpc_c (London)"
}

variable "vpc_a_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs in vpc_a (N. Virginia)"
}

variable "vpc_c_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs in vpc_c (London)"
}

variable "peering_connection_id" {
  type        = string
  description = "VPC Peering Connection ID"
}
