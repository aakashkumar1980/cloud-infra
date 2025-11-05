/** Expose a tidy map: vpc_name -> vpc_id */
output "vpc_ids" {
  description = "Map of VPC name -> VPC ID"
  value       = { for k, m in module.vpc : k => m.vpc_id }
}