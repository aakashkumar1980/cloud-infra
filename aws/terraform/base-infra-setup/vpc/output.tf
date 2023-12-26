output "output-vpc" {
  value = {for k,v in module.VPC: k=>v.output-vpc}
}

output "output-igw" {
  value = values(module.INTERNET_GATEWAY)[*].output-igw
}



