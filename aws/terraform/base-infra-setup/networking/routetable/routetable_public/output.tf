output "output-rt_public" {
  value = {for k,v in module.ROUTETABLE: k=>v.output-rt}
}
