/** Discover available AZs in this region */
data "aws_availability_zones" "this" {
  state = "available"
}