/**
  1. Subnet Calculator: https://www.davidc.net/sites/default/subnets/subnets.html
  2. Concept: https://www.howtoinmagento.com/2019/05/simply-calculate-aws-subnets-cidr.html
  3. Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  4. Online Terraform Console: https://terraform-online-console.com/

  Defining the network configuration for the region. e.g.:
  region_nvirginia (map)
  └─ vpc (map)
  | └─ vpc_a (object)
  | |   ├─ cidr_block (string): "10.0.0.0/24"
  | |   └─ subnets (map)
  | |     ├─ subnet1 (object)
  | |     │  ├─ type (string): "generic"
  | |     │  ├─ cidr_block (string): "10.0.0.0/28"
  | |     │  └─ availability_zone_index (string): "a"
  | |     └─ subnet2 (object)
  | |         ├─ type (string): "public"
  | |         ├─ cidr_block (string): "10.0.0.16/28"
  | |         └─ availability_zone_index (string): "a"
  | └─ vpc_b (object)  
  |    ...            
  |  
  region_london (map)     
**/

variable "region_configurations" {
  type = map(object({
    vpc = map(object({
      cidr_block = string
      subnets    = map(object({
        type                   = string
        cidr_block             = string
        availability_zone_index = string
      }))
    }))
  }))

  default = {
    region_nvirginia = {
      vpc = {
        vpc_a = {
          cidr_block = "10.0.0.0/24"
          subnets = {
            "1" = { type = "generic", cidr_block = "10.0.0.0/27", availability_zone_index = "a" }
            "2" = { type = "public",  cidr_block = "10.0.0.32/27", availability_zone_index = "a" }
            "3" = { type = "public",  cidr_block = "10.0.0.64/27", availability_zone_index = "b" }
            "4" = { type = "private", cidr_block = "10.0.0.96/27", availability_zone_index = "a" }
            "5" = { type = "private", cidr_block = "10.0.0.128/27", availability_zone_index = "b" }
            "6" = { type = "private", cidr_block = "10.0.0.160/27", availability_zone_index = "c" }
            # free CIDRs: 10.0.0.192/27, 10.0.0.224/27
          }
        }
        vpc_b = {
          cidr_block = "172.16.0.0/26"
          subnets = {
            "1" = { type = "generic", cidr_block = "172.16.0.0/28", availability_zone_index = "a" }
            "2" = { type = "public",  cidr_block = "172.16.0.16/28", availability_zone_index = "b" }
            "3" = { type = "private", cidr_block = "172.16.0.32/28", availability_zone_index = "c" }
            # free CIDRs: 172.16.0.48/28
          }
        }
      }
    },

    region_london = {
      vpc = {
        vpc_c = {
          cidr_block = "192.168.0.0/26"
          subnets = {
            "1" = { type = "generic", cidr_block = "192.168.0.0/28", availability_zone_index = "a" }
            "2" = { type = "public",  cidr_block = "192.168.0.16/28", availability_zone_index = "b" }
            "3" = { type = "private", cidr_block = "192.168.0.32/28", availability_zone_index = "c" }
            # free CIDRs: 192.168.0.48/28
          }
        },
        "vpc_acopy" = {
          cidr_block = "10.0.0.0/24"
          subnets = {
            "1" = { type = "generic", cidr_block = "10.0.0.0/27", availability_zone_index = "a" }
            "2" = { type = "public",  cidr_block = "10.0.0.192/27", availability_zone_index = "b" }
            "3" = { type = "private", cidr_block = "10.0.0.224/27", availability_zone_index = "c" }
            # free CIDRs: 10.0.0.32/27, 10.0.0.64/27, 10.0.0.96/27, 10.0.0.128/27, 10.0.0.160/27
          }
        }
      }
    }
  }
}
