output "output-vpc_c" {
  value = data.aws_vpc.vpc_c
}
output "output-subnet_private" {
  value = data.aws_subnet.subnet_private
}
output "output-sg_private" {
  value = data.aws_security_group.sg_private
}

