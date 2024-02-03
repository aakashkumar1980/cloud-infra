variable "ns" {
  default = null
}

variable "vpc_b-cluster" {
  default = null
}
variable "vpc_a" {
  default = null
}
variable "vpc_a-subnet_private" {
  default = null
}
variable "vpc_a-sg_private" {
  default = null
}
variable "vpc_b" {
  default = null
}
variable "vpc_b-subnet_private" {
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
variable "user_data" {
  default = null
}

variable "ingress-rules_map" {
  default = null
}
