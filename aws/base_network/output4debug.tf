output "debug" {
  value = [
    data.aws_availability_zones.nvirginia,
    data.aws_availability_zones.london
  ]
}
