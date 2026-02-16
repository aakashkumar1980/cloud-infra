/**
 * Routes Module - Variables
 */

variable "vpc_a_cidr" {
  type        = string
  description = "CIDR block of vpc_a"
}

variable "vpc_b_cidr" {
  type        = string
  description = "CIDR block of vpc_b"
}

variable "vpc_a_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs in vpc_a"
}

variable "vpc_b_route_table_ids" {
  type        = list(string)
  description = "List of route table IDs in vpc_b"
}

variable "peering_connection_id" {
  type        = string
  description = "VPC Peering Connection ID"
}
