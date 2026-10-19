resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_route_table_association" "public_subnet_association_eu_north_1a" {
  subnet_id      = aws_subnet.public_subnet_eu_north_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_eu_north_1a" {
  subnet_id      = aws_subnet.private_subnet_eu_north_1a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_eu_north_1b" {
  subnet_id      = aws_subnet.public_subnet_eu_north_1b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_eu_north_1b" {
  subnet_id      = aws_subnet.private_subnet_eu_north_1b.id
  route_table_id = aws_route_table.private_route_table.id
}
