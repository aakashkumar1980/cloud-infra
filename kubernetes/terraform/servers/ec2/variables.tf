variable "ns" {
  default = null
}
variable "base_ns" {
  default = null
}

variable "efs" {
  default = null
}
variable "servers" {
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

variable "efs_file_system" {
  default = null
}
variable "efs-output-sg" {
  default = null
}

variable "ami" {
  default = null
}
variable "keypair" {
  default = null
}
variable "user_data_ssm" {
  default = null
}

