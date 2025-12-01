/**
 * Instances Module - Variables
 */

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
}

variable "instance_a_subnet_id" {
  type        = string
  description = "Subnet ID for instance A (vpc_a public subnet)"
}

variable "instance_b_subnet_id" {
  type        = string
  description = "Subnet ID for instance B (vpc_b private subnet)"
}

variable "instance_a_sg_id" {
  type        = string
  description = "Security group ID for instance A"
}

variable "instance_b_sg_id" {
  type        = string
  description = "Security group ID for instance B"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
  default     = ""
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}
