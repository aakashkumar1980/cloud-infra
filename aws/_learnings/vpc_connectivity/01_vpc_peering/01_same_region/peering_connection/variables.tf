/**
 * Peering Connection Module - Variables
 */

variable "vpc_a_id" {
  type        = string
  description = "ID of vpc_a (requester VPC)"
}

variable "vpc_b_id" {
  type        = string
  description = "ID of vpc_b (accepter VPC)"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}
