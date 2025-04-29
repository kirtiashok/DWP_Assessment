# main.tf

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Subnets
resource "aws_subnet" "presentation_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "application_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "data_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false
}

# Security Groups
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
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

# Application Load Balancer (Presentation Tier)
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.presentation_subnet.id]
  enable_deletion_protection = false
}

# Application Servers (Application Tier)
resource "aws_launch_configuration" "app_server" {
  name          = "app-server-config"
  image_id      = "ami-0abcdef1234567890"  # Use an appropriate AMI
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.application_subnet.id]
  launch_configuration = aws_launch_configuration.app_server.id
}

# RDS Database Cluster (Data Tier)
resource "aws_rds_cluster" "db_cluster" {
  cluster_identifier = "app-db-cluster"
  engine             = "aurora"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  database_name      = "appdb"
}

# Monitoring with CloudWatch
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/vpc/application"
}

# IAM Role for EC2 (for accessing CloudWatch logs)
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2-cloudwatch-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:CreateLogStream"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
