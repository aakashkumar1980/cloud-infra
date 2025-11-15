module "NAT-INSTANCE" {
  source   = "nat_instance"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id  = each.value.id
  subnets = var.subnets

  ami           = var.ami
  keypair       = var.keypair
  instance_type = var.instance_type

  tag_path = each.value.tags["Name"]
}
