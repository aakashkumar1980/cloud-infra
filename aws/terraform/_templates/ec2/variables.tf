variable "instance_type" {
  default = null
}

variable "source_dest_check" {
  default = true
}
variable "subnet_id" {
  default = null
}
variable "security_groups" {
  default = null
}

variable "ami" {
  default = null
}
variable "keypair" {
  default = null
}
variable "user_data" {
  default = ""
}

variable "tag_path" {
  default = null
}
variable "entity_name" {
  default = null
}
