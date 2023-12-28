resource "aws_ec2_transit_gateway_vpc_attachment" "attach-vpc" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  dns_support        = "enable"

  tags = {
    Name = "${var.tag_path}.tgw_${var.entity_name}.attached-vpc_${data.aws_vpc.vpc.tags["Name"]}"
  }
}
