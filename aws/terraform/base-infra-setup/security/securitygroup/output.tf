output "output-sg_public" {
  value = { for k, v in module.SECURITYGROUP_PUBLIC : k => v.output-sg_public }
}

output "output-sg_private" {
  value = { for k, v in module.SECURITYGROUP_PRIVATE : k => v.output-sg_private }
}

