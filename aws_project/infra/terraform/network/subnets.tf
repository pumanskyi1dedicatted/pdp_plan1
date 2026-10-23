resource "aws_subnet" "public_subnet_eu_north_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  tags = {
    Name = "public_subnet_eu_north_1a"
  }
}

resource "aws_subnet" "public_subnet_eu_north_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
  tags = {
    Name = "public_subnet_eu_north_1b"
  }
}

resource "aws_subnet" "private_subnet_eu_north_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-north-1a"
  tags = {
    Name = "private_subnet_eu_north_1a"
  }
}

resource "aws_subnet" "private_subnet_eu_north_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-north-1b"
  tags = {
    Name = "private_subnet_eu_north_1b"
  }
}

resource "aws_subnet" "database_subnet_eu_north_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "eu-north-1a"
  tags = {
    Name = "database_subnet_eu_north_1a"
  }
}

resource "aws_subnet" "database_subnet_eu_north_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "eu-north-1b"
  tags = {
    Name = "database_subnet_eu_north_1b"
  }
}
