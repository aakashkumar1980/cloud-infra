/**
 * Instances Module - Variables
 */

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3a.nano"
}

/** Subnet IDs */
variable "bastion_subnet_id" {
  type        = string
  description = "Subnet ID for bastion (vpc_a public subnet)"
}

variable "vpc_a_private_subnet_id" {
  type        = string
  description = "Subnet ID for vpc_a private instance"
}

variable "vpc_b_private_subnet_id" {
  type        = string
  description = "Subnet ID for vpc_b private instance"
}

/** Security Group IDs */
variable "bastion_sg_id" {
  type        = string
  description = "Security group ID for bastion"
}

variable "vpc_a_private_sg_id" {
  type        = string
  description = "Security group ID for vpc_a private instance"
}

variable "vpc_b_private_sg_id" {
  type        = string
  description = "Security group ID for vpc_b private instance"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
  default     = ""
}

variable "private_key_pem" {
  type        = string
  description = "Private key PEM for SSH access to private instances"
  default     = ""
  sensitive   = true
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}
