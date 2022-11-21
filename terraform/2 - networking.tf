# Creating VPC

resource "aws_vpc" "web-app" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Project = "movie-web-app"
  }
}

#NAT Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.web-app.id

  tags = {
    Project = "movie-web-app"
  }
}


# Public Subnets
resource "aws_subnet" "public-eu-west-2a" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

}

resource "aws_subnet" "public-eu-west-2b" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-eu-west-2c" {
  vpc_id                  = aws_vpc.web-app.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true
}

#route table and table_associations for each of the above public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.web-app.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public-eu-west-2a" {
  subnet_id      = aws_subnet.public-eu-west-2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-eu-west-2b" {
  subnet_id      = aws_subnet.public-eu-west-2b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-eu-west-2c" {
  subnet_id      = aws_subnet.public-eu-west-2c.id
  route_table_id = aws_route_table.public.id
}


# Security Groups

resource "aws_security_group" "container-sg" {
  name        = "ContainerFromAlb-SG"
  description = "Allows inbound traffic from the ALB security group"
  vpc_id      = aws_vpc.web-app.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    security_groups  = [aws_security_group.alb.id]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "ApplicationLoadBalancer-SG"
  description = "Allows inbound port 80 traffic from anywhere"
  vpc_id      = aws_vpc.web-app.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}