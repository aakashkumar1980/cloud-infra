output "output-rt_private" {
  value = { for k, v in module.ROUTETABLE : k => v.output-rt }
}
