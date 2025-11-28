# Get available availability zones for each region

data "aws_availability_zones" "nvirginia" {
  provider = aws.nvirginia
  state    = "available"
}

data "aws_availability_zones" "london" {
  provider = aws.london
  state    = "available"
}
