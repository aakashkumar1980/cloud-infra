output "output-sg_public" {
  value = {for k,v in module.SECURITYGROUP_PUBLIC: k=>v.output-sg_public}
}