resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name  = "${var.tag_name}-VPC"
    Owner = "${var.tag_owner}"

  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name  = "${var.tag_name}-IGW"
    Owner = "${var.tag_owner}"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.subnet_cidrs_public)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidrs_public[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.tag_name}-VPC-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.subnet_cidrs_private)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_cidrs_private[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.tag_name}-VPC-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "${var.tag_name}-public-rt"
  }
}

resource "aws_route_table_association" "rt_associate_public" {
  count          = length(var.subnet_cidrs_public)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.main_public_rt.id
}

resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "${var.tag_name}-private-rt"
  }
}

resource "aws_route_table_association" "rt_associate_private" {
  count          = length(var.subnet_cidrs_private)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.main_private_rt.id
}

resource "aws_vpc_endpoint" "vpc_endpoint_s3" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = var.s3_vpc_endpoint_service_name
  vpc_endpoint_type = "Gateway"
  depends_on        = [aws_s3_bucket.s3_bucket_content]
  tags = {
    Name = "${var.tag_name}-VPC-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "rt_associate_s3_endpoint" {
  route_table_id  = aws_route_table.main_private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.vpc_endpoint_s3.id
}

resource "aws_route" "outbound-nat-route" {
  route_table_id         = aws_route_table.main_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
  depends_on             = [aws_instance.nat_instance]
}
