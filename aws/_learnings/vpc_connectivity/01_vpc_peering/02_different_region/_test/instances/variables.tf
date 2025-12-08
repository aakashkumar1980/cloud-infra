/**
 * Instances Module - Variables (Cross-Region)
 */

variable "ami_id_nvirginia" {
  type        = string
  description = "AMI ID for EC2 instances in N. Virginia"
}

variable "ami_id_london" {
  type        = string
  description = "AMI ID for EC2 instances in London"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3a.nano"
}

/** Subnet IDs */
variable "bastion_subnet_id" {
  type        = string
  description = "Subnet ID for bastion (vpc_a public subnet, N. Virginia)"
}

variable "vpc_a_private_subnet_id" {
  type        = string
  description = "Subnet ID for vpc_a private instance (N. Virginia)"
}

variable "vpc_c_private_subnet_id" {
  type        = string
  description = "Subnet ID for vpc_c private instance (London)"
}

/** Security Group IDs */
variable "bastion_sg_id" {
  type        = string
  description = "Security group ID for bastion (N. Virginia)"
}

variable "vpc_a_private_sg_id" {
  type        = string
  description = "Security group ID for vpc_a private instance (N. Virginia)"
}

variable "vpc_c_private_sg_id" {
  type        = string
  description = "Security group ID for vpc_c private instance (London)"
}

variable "key_name_nvirginia" {
  type        = string
  description = "EC2 key pair name for SSH access in N. Virginia"
  default     = ""
}

variable "key_name_london" {
  type        = string
  description = "EC2 key pair name for SSH access in London"
  default     = ""
}

variable "private_key_pem" {
  type        = string
  description = "Private key PEM for SSH access to private instances"
  default     = ""
  sensitive   = true
}

variable "name_suffix_nvirginia" {
  type        = string
  description = "Suffix for resource naming in N. Virginia"
}

variable "name_suffix_london" {
  type        = string
  description = "Suffix for resource naming in London"
}
