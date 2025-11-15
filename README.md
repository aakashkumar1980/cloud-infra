# AWS CIDR (Classless Inter-Domain Routing)
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

  



# Miscellaneous
## Terraform Apply with Profile
```shell
$ terraform apply -var="profile=dev" -auto-approve
```
