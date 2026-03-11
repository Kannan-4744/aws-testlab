resource "aws_vpc" "eks_vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "eks-angular-vpc"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.eks_vpc.id
}

############################
# Public Subnets
############################

resource "aws_subnet" "public1" {

  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public2" {

  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

############################
# Private Subnets
############################

resource "aws_subnet" "private1" {

  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private2" {

  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.4.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

############################
# NAT Gateway
############################

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
}

############################
# Route Tables
############################

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.eks_vpc.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public1" {

  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public2" {

  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.eks_vpc.id

  route {

    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private1" {

  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private2" {

  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}