output "output-rt_generic" {
  value = { for k, v in module.ROUTETABLE : k => v.output-rt }
}
