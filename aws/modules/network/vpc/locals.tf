/** Map AZ letter → index into data.aws_availability_zones.this.names */
locals {
  azs = data.aws_availability_zones.this.names

  az_letter_index = {
    a = 0, b = 1, c = 2, d = 3, e = 4, f = 5
  }

  /* Classify subnets by type for routing decisions */
  subnets_public  = { for k, s in var.subnets : k => s if lower(s.type) == "public"  }
  subnets_private = { for k, s in var.subnets : k => s if lower(s.type) == "private" }
  subnets_generic = { for k, s in var.subnets : k => s if lower(s.type) == "generic" }

  tags = var.tags
}