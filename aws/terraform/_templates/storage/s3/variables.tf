variable "bucket_name" {
  default = null
}
variable "policy" {
  default = null
}

variable "acl" {
  default = "private"
}
variable "block_public_acls" {
  default = true
}
variable "block_public_policy" {
  default = true
}
variable "ignore_public_acls" {
  default = true
}
variable "restrict_public_buckets" {
  default = true
}


variable "tag_path" {
  default = null
}