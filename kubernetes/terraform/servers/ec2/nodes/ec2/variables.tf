variable "vpc_b-subnet_private" {
  default = null
}
variable "security_group_ids" {
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
**/

variable "tag_path" {
  default = null
}
variable "entity_name" {
  default = null
}

