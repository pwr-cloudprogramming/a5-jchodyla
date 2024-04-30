provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow SSH, HTTP, and custom TicTacToe ports"
  vpc_id      = aws_vpc.my_vpc.id

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

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami                         = "ami-00b535e0e5fc28916"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.my_subnet.id
  associate_public_ip_address = true
  # Security group for EC2 instance
  vpc_security_group_ids = [aws_security_group.my_security_group.id]


user_data = <<-EOF
              #!/bin/bash
               #sudo apt update -y
               #sudo apt install -y docker.io
               #service docker start
              
              # Retrieve IP address using metadata script
              API_URL="http://169.254.169.254/latest/api"
              TOKEN=$(curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
              TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
              METADATA_URL="http://169.254.169.254/latest/meta-data"
              AZONE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/placement/availability-zone)
              IP_V4=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4)
              INTERFACE=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/ | head -n1)
              SUBNET_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/subnet-id)
              VPC_ID=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/network/interfaces/macs/$INTERFACE/vpc-id)

              echo "Your EC2 instance works in: AvailabilityZone: $AZONE, VPC: $VPC_ID, VPC subnet: $SUBNET_ID, IP address: $IP_V4"
              
              echo "$IP_V4" > /tmp/ec2_ip_address.txt
              
              echo "-----BEGIN OPENSSH PRIVATE KEY-----" > ~/.ssh/myrepokey
              echo "-----END OPENSSH PRIVATE KEY-----" >> ~/.ssh/myrepokey
              echo "Host github.com-app-repo" > ~/.ssh/config
              echo "    Hostname github.com" >> ~/.ssh/config
              echo "    IdentityFile=/root/.ssh/myrepokey" >> ~/.ssh/config
              chmod 600 ~/.ssh/myrepokey
              chmod 600 ~/.ssh/config

              git clone https://github.com/pwr-cloudprogramming/a5-jchodyla.git

              sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
              sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
              sudo chmod +x /usr/bin/docker-compose

              cd a5-jchodyla
			
              docker-compose build --build-arg IP="$IP_V4" --no-cache

              docker-compose up -d
          EOF
  user_data_replace_on_change = true
  tags = {
    Name = "TerraformTicTacToe"
  }

}