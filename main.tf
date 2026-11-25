provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "bosh-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "bosh-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bosh-gw"
  }
}

resource "aws_route_table" "routing" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "bosh-route-tbw"
  }
}

resource "aws_route_table_association" "bosh-route" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.routing.id
}

resource "aws_security_group" "bosh-traffic" {
  name        = "allow_ssh"
  description = "Allow ssh traffic to EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.bosh-traffic.id
  cidr_ipv4         = "87.227.173.210/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.bosh-traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "bosh-deployer-key"
  public_key = file("~/.ssh/bosh_key.pub")
}

resource "aws_eip" "bosh-eip" {
  domain = "vpc"
}

resource "aws_eip_association" "bosh-eip-ass" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.bosh-eip.id
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.bosh-traffic.id]

  tags = {
    Name = var.instance_name
  }
}
