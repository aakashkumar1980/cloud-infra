# AWS CIDR (Classless Inter-Domain Routing)

---

## Format
```
X.X.X.X/Y
e.g. xxxxxxxx . xxxxxxxx . xxxxxxxx . xxxxxxxx / Y
     (8 bits)   (8 bits)   (8 bits)   (8 bits)   |
                         |                       |
                         |                       |
                         |                        -> How big the network
                         |                           Examples:
                         |                           - /16 (16 bits locked from left)
                         |                             Range: X.X.0.0 - X.X.255.255
                         |                                    (xxxxxxxx.xxxxxxxx.00000000.00000000 - xxxxxxxx.xxxxxxxx.11111111.11111111) 
                         |                                    = 65,536 IP addresses (max VPC size in AWS)
                         |                           
                         |                           - /28 (28 bits locked from left)
                         |                             Range: X.X.X.0 - X.X.X.15
                         |                                    (xxxxxxxx.xxxxxxxx.xxxxxxxx.xxxx0000 - xxxxxxxx.xxxxxxxx.xxxxxxxx.xxxx1111)
                         |                                    = 16 IP addresses (min VPC size in AWS)
                         |
                          -> Starting address of the network
                             AWS recommends using these private ranges:
                             - 10.0.0.0/Y
                             - 172.16.0.0/Y
                             - 192.168.0.0/Y
```
## Subnets
- Must be within your VPC CIDR range
- AWS reserves **5 IP addresses** in each subnet:
  - First 4 addresses (network, router, DNS, future use)
  - Last 1 address (broadcast)
- So a /28 subnet has 16 total IPs, but only **11 usable**

###  Dividing Networks
https://www.davidc.net/sites/default/subnets/subnets.html
<br><br>



# TERRAFORM LEARNING

---

## Terraform concepts:
- **map** in terraform is a collection of key-value pairs.
```hcl
variable "example_map" {
  type = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
    ...
  }
}
```
<br>

## Terraform functions: `lookup()` and `merge()`
`lookup(map, key, default)`
- Returns the value for `key` from `map`.
- If `key` is not present, returns `default`.

`merge(map1, map2, ...)`
- Returns a new map that combines the input maps.
- Keys in later maps override earlier maps.
- Merge is **shallow** (does not deep-merge nested maps).
  NOTE: For deep merging, consider using `deepmerge()` from the `terraform` `stdlib` module.
<br><br>



# MISCELLANEOUS

---
## Terraform Apply with Profile
```shell
$ terraform apply -var="profile=dev" -var="enable_test=true" -auto-approve
```