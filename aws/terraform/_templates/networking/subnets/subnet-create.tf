resource "aws_subnet" "subnets" {
  vpc_id = var.vpc_id

  availability_zone       = "${data.aws_region.current.name}${var.subnet-availability_zone-index}"
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    "Name" = "${var.tag_path}.subnet_${var.subnet-type}-az_${var.subnet-availability_zone-index}"
  }
}
