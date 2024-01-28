module "SG-SECONDARY_CONTROL_PLANE-REGION_NVIRGINIA" {
  source = "../../../../../aws/terraform/_templates/security/securitygroup"
  providers = {
    aws = aws.rnvg
  }

  count       = var.primary_vpc_name == "vpc_a" || var.primary_vpc_name == "vpc_b" ? 1 : 0
  vpc_id      = var.primary_vpc.id
  tag_path    = "${var.ns}.${var.primary_vpc_name}"
  entity_name = "secondary_control_plane"
}
module "SG-SECONDARY_CONTROL_PLANE-INGRESS_RULES-REGION_NVIRGINIA" {
  source = "../../../../../aws/terraform/_templates/security/securitygroup/ingress"
  providers = {
    aws = aws.rnvg
  }

  count       = var.primary_vpc_name == "vpc_a" || var.primary_vpc_name == "vpc_b" ? length(var.ingress-rules_map) : 0
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  protocol    = element(var.ingress-rules_map, count.index).protocol
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = element(var.ingress-rules_map, count.index).cidr_blocks

  securitygroup_id = module.SG-SECONDARY_CONTROL_PLANE-REGION_NVIRGINIA[0].output-sg.id
}
