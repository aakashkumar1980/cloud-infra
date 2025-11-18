/**
 * Outputs the IDs of the created route tables.
 */
output "route_table_ids" {
  value = { for k, v in aws_route_table.public : k => v.id }
}
