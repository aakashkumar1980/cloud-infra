/**
 * Peering Connection Module - Variables (Cross-Region)
 */

variable "vpc_a_id" {
  type        = string
  description = "ID of vpc_a (requester VPC in N. Virginia)"
}

variable "vpc_c_id" {
  type        = string
  description = "ID of vpc_c (accepter VPC in London)"
}

variable "peer_region" {
  type        = string
  description = "AWS region of the peer (accepter) VPC"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}
