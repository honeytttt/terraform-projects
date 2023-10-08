provider "aws" {
  region = "ap-southeast-1"

}
variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "vpc cidr range"
}
resource "aws_key_pair" "practice1-key" {
  key_name   = "practice1 for terraform"
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "aws_vpc" "practice1-vpc" {
  cidr_block = var.cidr
}
resource "aws_subnet" "practice1-sn" {
  vpc_id                  = aws_vpc.practice1-vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "practice1-igw" {
  vpc_id = aws_vpc.practice1-vpc.id
}
resource "aws_route_table" "practice1-rt" {
  vpc_id = aws_vpc.practice1-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.practice1-igw.id
  }
}
resource "aws_route_table_association" "practice1-rta1" {
  subnet_id      = aws_subnet.practice1-sn.id
  route_table_id = aws_route_table.practice1-rt.id
}
resource "aws_security_group" "practice1-sg" {
  name   = "practice1sg"
  vpc_id = aws_vpc.practice1-vpc.id
  ingress {
    description = "http from vpc"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "practice1-sg"
  }

}
resource "aws_instance" "practice1" {
  ami                    = "ami-0df7a207adb9748c7"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.practice1-key.key_name
  vpc_security_group_ids = [aws_security_group.practice1-sg.id]
  subnet_id              = aws_subnet.practice1-sn.id

  tags = {
    Name = "Jenkins-Master"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip    
  }
    provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",
    ]
  }
}
output "public-ip-address" {
  value = aws_instance.practice1.public_ip
}