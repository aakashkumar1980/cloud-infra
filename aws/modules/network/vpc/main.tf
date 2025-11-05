/** Core VPC */
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-vpc" })
}

/** Internet Gateway */
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-igw" })
}

/** Public subnets */
resource "aws_subnet" "public" {
  for_each = local.subnets_public

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  # Resolve AZ by letter (“a” → azs[0], etc.)
  availability_zone = local.azs[ local.az_letter_index[ lower(each.value.availability_zone_index) ] ]

  tags = merge({
    Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-public-${each.key}"
    Tier = "public"
  })
}

/** Public route table + default route via IGW */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-rt-public" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

/** Private subnets */
resource "aws_subnet" "private" {
  for_each = local.subnets_private

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = local.azs[ local.az_letter_index[ lower(each.value.availability_zone_index) ] ]

  tags = merge({
    Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-private-${each.key}"
    Tier = "private"
  })
}

/** Generic subnets (no default Internet/NAT route, “islands” by default) */
resource "aws_subnet" "generic" {
  for_each = local.subnets_generic

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = local.azs[ local.az_letter_index[ lower(each.value.availability_zone_index) ] ]

  tags = merge({
    Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-generic-${each.key}"
    Tier = "generic"
  })
}

/** NAT gateways (created only if we have private subnets) */
resource "aws_eip" "nat" {
  count  = length(local.subnets_private) == 0 ? 0 : (var.single_nat_gateway ? 1 : max(1, length(aws_subnet.public)))
  domain = "vpc"
  tags   = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-eip-nat-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = length(local.subnets_private) == 0 ? 0 : (var.single_nat_gateway ? 1 : max(1, length(aws_subnet.public)))
  allocation_id = aws_eip.nat[count.index].id

  # Place NAT(s) in public subnets; single NAT uses the first public subnet
  subnet_id  = element([for s in aws_subnet.public : s.id], var.single_nat_gateway ? 0 : count.index)
  tags       = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-nat-${count.index}" })
  depends_on = [aws_internet_gateway.this]
}

/** Private route tables: single or per-AZ depending on single_nat_gateway */
resource "aws_route_table" "private" {
  count = length(local.subnets_private) == 0 ? 0 : (var.single_nat_gateway ? 1 : max(1, length(aws_nat_gateway.this)))

  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[ var.single_nat_gateway ? 0 : count.index ].id
  }
  tags = merge({Name = "${var.tags.project}-${var.tags.env}-${var.tags.region}-${var.tags.name}-rt-private-${count.index}" })
}

/** Associate private subnets round-robin across the available private route tables */
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[ tonumber(each.key) % max(1, length(aws_route_table.private)) ].id
}
