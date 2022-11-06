# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.vpc_name
  }
}

# public subnet
resource "aws_subnet" "public_subnet" {
  for_each                = var.public_subnet
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = "true"
  tags = {
    Name = each.value.name
  }
}

# private subnet
resource "aws_subnet" "private_subnet" {
  for_each                = var.private_subnet
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = "false"
  tags = {
    Name = each.value.name
  }
}

# internet_gateway
resource "aws_internet_gateway" "main_igw" {
  count  = var.public_subnet != null ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.main_igw_name
  }
}

# routetable
resource "aws_route_table" "public_routetable" {
  for_each = var.public_subnet
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.public_routetable_name}-${each.key}"
  }
}

resource "aws_route_table" "private_routetable" {
  for_each = var.private_subnet
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.private_routetable_name}-${each.key}"
  }
}

# igw route
resource "aws_route" "public_route" {
  for_each               = var.public_subnet
  route_table_id         = aws_route_table.public_routetable[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw[0].id
}

# other route
# issue https://github.com/hashicorp/terraform-provider-aws/issues/17198

## public 
resource "aws_route" "other_public_route" {
  for_each                  = var.other_public_route
  route_table_id            = aws_route_table.public_routetable[each.value.target_subnet].id
  destination_cidr_block    = each.value.destination_cidr_block
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
}

## private 
resource "aws_route" "other_private_route" {
  for_each                  = var.other_private_route
  route_table_id            = aws_route_table.private_routetable[each.value.target_subnet].id
  destination_cidr_block    = each.value.destination_cidr_block
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
}

# route_table_association
resource "aws_route_table_association" "public_routetable_association" {
  for_each       = var.public_subnet
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_routetable[each.key].id
}

resource "aws_route_table_association" "private_routetable_association" {
  for_each       = var.private_subnet
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_routetable[each.key].id
}

# nat
resource "aws_nat_gateway" "main_nat" {
  for_each      = var.nat_gateway_create == "true" ? var.public_subnet : {}
  allocation_id = aws_eip.main_nat_gateway[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id

  tags = {
    Name = "main_nat_${each.key}"
  }

}

# eip
resource "aws_eip" "main_nat_gateway" {
  for_each = var.nat_gateway_create == "true" ? var.public_subnet : {}
  vpc      = true
}

# nat_route
resource "aws_route" "nat_private_route" {
  for_each               = var.nat_gateway_create == "true" ? zipmap(keys(var.public_subnet), keys(var.private_subnet)) : {}
  route_table_id         = aws_route_table.private_routetable[each.value].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_nat[each.key].id
}

resource "aws_route_table_association" "nat_private_routetable_association" {
  for_each       = var.nat_gateway_create == "true" ? var.private_subnet : {}
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_routetable[each.key].id
}


output "mainvpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  value = {
    for k, v in aws_subnet.private_subnet : k => v.id
  }
}
output "public_routetable" {
  value = {
    for k, v in aws_route_table.public_routetable : k => v.id
  }
}

output "private_routetable" {
  value = {
    for k, v in aws_route_table.private_routetable : k => v.id
  }
}
