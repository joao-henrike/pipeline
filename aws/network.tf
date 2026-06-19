resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-techstock-aws" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw-techstock" }
}

resource "aws_subnet" "public_ec2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Permite que a EC2 acesse a internet para baixar pacotes
  tags                    = { Name = "subnet-publica-backend" }
}

resource "aws_subnet" "private_rds_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subnet-privada-db-a" }
}

resource "aws_subnet" "private_rds_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "subnet-privada-db-b" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-publica-techstock" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_ec2.id
  route_table_id = aws_route_table.public_rt.id
}
