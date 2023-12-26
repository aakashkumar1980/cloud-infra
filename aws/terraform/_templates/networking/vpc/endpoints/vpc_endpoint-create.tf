resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = var.endpoint_type

  tags = {
    "Name" = "${var.tag_path}.endpoint_${var.entity_name}"
  }  
}
