resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_eu_north_1a.id
  depends_on    = [aws_internet_gateway.my_igw]
  tags = {
    Name = "my_nat_gateway"
  }
}
