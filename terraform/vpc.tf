# Create a VPC
resource "aws_vpc" "browny_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "browny_vpc"
  }
}

# Fetch availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.browny_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.browny_vpc.id

  tags = {
    Name = "private_subnet_${count.index}"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.browny_vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.browny_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${count.index}"
  }
}

# Create an Internet Gateway for the public subnets
resource "aws_internet_gateway" "browny_igw" {
  vpc_id = aws_vpc.browny_vpc.id

  tags = {
    Name = "browny_igw"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.browny_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.browny_igw.id
}

# Create an Elastic IP for each NAT Gateway
resource "aws_eip" "browny_eip" {
  count      = var.az_count
  depends_on = [aws_internet_gateway.browny_igw]
}

# Create a NAT Gateway for each private subnet
resource "aws_nat_gateway" "browny_natgw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.browny_eip.*.id, count.index)
  depends_on    = [aws_internet_gateway.browny_igw]

  tags = {
    Name = "browny_natgw_${count.index}"
  }
}

# Create route tables for private subnets
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.browny_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.browny_natgw.*.id, count.index)
  }

  tags = {
    Name = "private_route_table_${count.index}"
  }
}

# Associate route tables with private subnets
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
