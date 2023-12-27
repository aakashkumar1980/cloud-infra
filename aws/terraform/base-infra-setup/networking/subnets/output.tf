output "output-subnets" {
  value = values(module.SUBNETS)[*].output-subnets
}
