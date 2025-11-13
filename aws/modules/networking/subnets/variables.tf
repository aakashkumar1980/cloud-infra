variable "vpcs"            { type = map(any) }
variable "vpc_ids"         { type = map(string) }
variable "az_names"        { type = list(string) }
variable "az_letter_to_ix" { type = map(number) }
variable "common_tags"     { type = map(string) }
variable "region"          { type = string }
