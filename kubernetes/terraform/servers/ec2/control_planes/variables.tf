variable "ns" {
  default = null
}
variable "base_ns" {
  default = null
}

variable "cluster" {
  default = null
}
variable "vpc_a" {
  default = null
}
variable "vpc_b" {
  default = null
}
variable "vpc_a-subnet_private" {
  default = null
}
variable "vpc_b-subnet_private" {
  default = null
}
variable "vpc_a-sg_private" {
  default = null
}
variable "vpc_b-sg_private" {
  default = null
}

variable "ami" {
  default = null
}
variable "instance_type" {
  default = null
}
variable "keypair" {
  default = null
}
variable "iam_instance_profile" {
  default = null
}
variable "user_data_ssm" {
  default = null
}

/**
variable "user_data_efs" {
  default = null
}
variable "efs-output-sg" {
  default = null
}
variable "efs-ingress-rules_map" {
  default = null
}
**/

variable "ingress-rules_map" {
  default = null
}
