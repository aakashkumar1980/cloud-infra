output "output-nacl_generic" {
  value = {for k,v in module.NACL_GENERIC: k=>v.output-nacl_generic}
}

output "output-nacl_public" {
  value = {for k,v in module.NACL_PUBLIC: k=>v.output-nacl_public}
}

output "output-nacl_private" {
  value = {for k,v in module.NACL_PRIVATE: k=>v.output-nacl_private}
}
