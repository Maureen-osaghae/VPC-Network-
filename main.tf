# Create locals to store number of subnets
locals {
  number_of_public_subnets  = length(var.lab_vpc.availability_zones)
  number_of_private_subnets = length(var.lab_vpc.availability_zones)
}

data "aws_region" "current" {}

# Create VPC Resource
resource "aws_vpc" "demo" {
  cidr_block           = var.lab_vpc.cidr_block
  enable_dns_hostnames = var.lab_vpc.enable_dns_host_names
  enable_dns_support   = var.lab_vpc.enable_dns_support
  tags                 = var.lab_vpc.tags
}

# Create IGW for VPC
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "vpc_igw"
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  count             = local.number_of_public_subnets
  vpc_id            = aws_vpc.demo.id
  availability_zone = var.lab_vpc.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.demo.cidr_block, 2, count.index + 1)# function that automatically creates subnet CIDR blocks based on the VPC CIDR block
  
  tags = {
    Name = "vpc_public_${count.index + 1}"
  }
}

# Create a Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate public subnets to the public route table
resource "aws_route_table_association" "public_route_table_association" {
  count          = local.number_of_public_subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create private subnet
resource "aws_subnet" "private" {
  count             = local.number_of_private_subnets
  vpc_id            = aws_vpc.demo.id
  availability_zone = var.lab_vpc.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.demo.cidr_block, 4, count.index + 1)

  tags = {
    Name = "vpc_private_${count.index + 1}"
  }
}

# Create private route table (one per subnet)
resource "aws_route_table" "private_route_table" {
  count  = local.number_of_private_subnets
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private_ngw[count.index].id
  }

  tags = {
    Name = "private_route_table_${count.index + 1}"
  }
}

# Associate private subnets to their route tables
resource "aws_route_table_association" "private_route_table_association" {
  count          = local.number_of_private_subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "ngw_eip" {
  count  = local.number_of_public_subnets
  domain = "vpc"

  tags = {
    Name = "vpc_eip_${count.index + 1}"
  }
}

# Create NAT Gateways
resource "aws_nat_gateway" "private_ngw" {
  count         = local.number_of_public_subnets #creates a NAT Gateway for each public subnet
  allocation_id = aws_eip.ngw_eip[count.index].id # assigns an Elastic IP to each NAT Gateway
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.demo_igw]

  tags = {
    Name = "vpc_ngw_${count.index + 1}"
  }
}
