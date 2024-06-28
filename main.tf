

provider "aws" {
  region = "eu-north-1"
}
# VPC
resource "aws_vpc" "test_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "test_vpc"
  }
}
# Public subnetss
resource "aws_subnet" "public_subnet" {
  tags = {
    Name = "public_subnet"
  }
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.test_vpc.id
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "public_subnet2" {
  tags = {
    Name = "public_subnet"
  }
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.test_vpc.id
  availability_zone = var.availability_zones[1]
}


resource "aws_subnet" "private_subnet" {
  tags = {
    Name = "privat_subnet"
  }
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.test_vpc.id
  availability_zone = var.availability_zones[0]
}

resource "aws_internet_gateway" "test_igw" {
  tags = {
    Name = "test_igw"
  }
  vpc_id = aws_vpc.test_vpc.id
}
resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.public_subnet.id
  allocation_id = aws_eip.nat_eip.id 
 tags = {
    Name = "nat_gateway"
  }



}
# Route tables for the subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "public_route_table"
  }
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "private_route_table"
  }
}
# Route the public subnet traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public_route_table.id
  gateway_id             = aws_internet_gateway.test_igw.id
  destination_cidr_block = "0.0.0.0/0"
}
# Route NAT Gateway
resource "aws_route" "nat_ngw_route" {
  route_table_id         = aws_route_table.private_route_table.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}
# Associate the newly created route tables to the subnets
resource "aws_route_table_association" "public_route_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_route_table_association" "private_route_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet.id
}

resource "aws_instance" "instance" {

  ami            = var.amis
  instance_type        = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name               =  var.test_key
  subnet_id     = aws_subnet.public_subnet.id
  lifecycle {
    create_before_destroy = true
  }

    tags = {
    Name = "test_instance"
  }
}

resource "aws_instance" "instance2" {

  ami            = var.amis
  instance_type        = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name               =  var.test_key
  subnet_id     = aws_subnet.private_subnet.id
  lifecycle {
    create_before_destroy = true
  }

    tags = {
    Name = "test_instance2"
  }
}


# Load Balancer ALB
resource "aws_lb" "test_lb" {
  name               = "testlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    aws_security_group.instance_sg.id
  ]
  subnets            = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet2.id
    
   
  ]

  tags = {
    Name = "test_lb"
  }
}

# Target Group
resource "aws_lb_target_group" "test_tg" {
  name     = "testlb1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id

  health_check {
    path = var.health_check_path
  }
}
# Security Group for EC2 instances
resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


   ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance_sg"
  }
}

# Listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test_tg.arn
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain= "vpc"

  tags = {
    Name = "nat_eip"
  }
}


