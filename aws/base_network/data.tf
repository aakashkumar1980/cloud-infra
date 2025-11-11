/**
 * Data Sources
 *
 * - Pull available AZ names in each region to convert letter suffix (a/b/c) into AZ names.
 */
data "aws_availability_zones" "nvirginia" {
  provider = aws.nvirginia
  state    = "available"
}

data "aws_availability_zones" "london" {
  provider = aws.london
  state    = "available"
}
