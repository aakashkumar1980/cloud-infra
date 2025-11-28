/**
 * Data Sources
 *
 * Fetches the list of available availability zones in each region.
 * This is used to map zone letters (a, b, c) to actual zone names
 * like us-east-1a, eu-west-2b, etc.
 */
data "aws_availability_zones" "nvirginia" {
  provider = aws.nvirginia
  state    = "available"
}

data "aws_availability_zones" "london" {
  provider = aws.london
  state    = "available"
}
