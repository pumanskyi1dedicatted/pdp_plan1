output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_id_eu_north_1a" {
  value = aws_subnet.public_subnet_eu_north_1a.id
}

output "private_subnet_id_eu_north_1a" {
  value = aws_subnet.private_subnet_eu_north_1a.id
}

output "public_subnet_id_eu_north_1b" {
  value = aws_subnet.public_subnet_eu_north_1b.id
}

output "private_subnet_id_eu_north_1b" {
  value = aws_subnet.private_subnet_eu_north_1b.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.my_nat_gateway.id
}
