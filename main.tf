# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnet
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create security group
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

# Create EC2 instance
resource "aws_instance" "my_instance" {
  ami                         = "ami-00b535e0e5fc28916"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.my_subnet.id
  associate_public_ip_address = true
  # Security group for EC2 instance
  vpc_security_group_ids = [aws_security_group.my_security_group.id]


  # User data for installing dependencies and running TicTacToe app
user_data = <<-EOF
              #!/bin/bash
              AZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              IP_V4=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
              SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -n1)/subnet-id)
              VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -n1)/vpc-id)
              
              echo "Your EC2 instance works in :AvailabilityZone: $AZONE / VPC: $VPC_ID / VPC subnet: $SUBNET_ID / IP address: $IP_V4"
              
              # Save IP address to a file
              echo "$IP_V4" > /tmp/ec2_ip_address.txt
              
              # Provide deploy key directly in user data (not recommended for production)
              echo "-----BEGIN OPENSSH PRIVATE KEY-----" > ~/.ssh/myrepokey
              echo "-----END OPENSSH PRIVATE KEY-----" >> ~/.ssh/myrepokey
              echo "Host github.com-app-repo" > ~/.ssh/config
              echo "    Hostname github.com" >> ~/.ssh/config
              echo "    IdentityFile=/root/.ssh/myrepokey" >> ~/.ssh/config
              chmod 600 ~/.ssh/myrepokey
              chmod 600 ~/.ssh/config

              # Clone GitHub repository using deploy key
              git clone https://github.com/pwr-cloudprogramming/a5-jchodyla.git

              sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
              sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
              sudo chmod +x /usr/bin/docker-compose

              # Change to the directory containing your cloned repository
              cd a5-jchodyla

              # Build Docker containers
              docker-compose build --build-arg ip="$IP_V4" --no-cache

              # Start Docker containers
              docker-compose up -d
          EOF
  user_data_replace_on_change = true
  tags = {
    Name = "TerraformTicTacToe"
  }

}