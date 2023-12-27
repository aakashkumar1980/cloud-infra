module "NACL_GENERIC" {
  source   = "./nacl_generic"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id   = each.value.id
  subnets  = var.subnets
  tag_path = each.value.tags["Name"]

  ingress-rules_map = concat(
    var.ingress-rules_map,
    [
      {
        # epidermal port
        protocol   = "tcp"
        from_port  = "32768"
        to_port    = "65535"
        cidr_block = "0.0.0.0/0"
      }
    ]
  )
  egress-rules_map = var.egress-rules_map
}

module "NACL_PUBLIC" {
  source   = "./nacl_public"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id   = each.value.id
  subnets  = var.subnets
  tag_path = each.value.tags["Name"]

  ingress-rules_map = concat(
    var.ingress-rules_map,
    [
      {
        # epidermal port
        protocol   = "tcp"
        from_port  = "32768"
        to_port    = "65535"
        cidr_block = "0.0.0.0/0"
      }
    ]
  )
  egress-rules_map = var.egress-rules_map
}

module "NACL_PRIVATE" {
  source   = "./nacl_private"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id         = each.value.id
  subnets        = var.subnets
  tag_path       = each.value.tags["Name"]
  vpc_cidr_block = each.value.cidr_block

  ingress-rules_map = concat(
    var.ingress-rules_map,
    [
      {
        # epidermal port
        protocol   = "tcp"
        from_port  = "32768"
        to_port    = "65535"
        cidr_block = "0.0.0.0/0"
      }
    ]
  )
  egress-rules_map = var.egress-rules_map
}

