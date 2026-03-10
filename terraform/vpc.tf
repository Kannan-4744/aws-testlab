resource "aws_vpc" "main" {

 cidr_block = var.vpc_cidr

 enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {

 vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public1" {

 vpc_id = aws_vpc.main.id

 cidr_block = "10.0.1.0/24"

 availability_zone = "eu-west-1a"

 map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {

 vpc_id = aws_vpc.main.id

 cidr_block = "10.0.2.0/24"

 availability_zone = "eu-west-1b"

 map_public_ip_on_launch = true
}