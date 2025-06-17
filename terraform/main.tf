# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Random suffix for unique resource names
resource "random_string" "resource_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for data and models
resource "aws_s3_bucket" "kidney_disease_bucket" {
  bucket = "kidney-disease-${random_string.resource_suffix.result}"
}

resource "aws_s3_bucket_versioning" "kidney_disease_bucket_versioning" {
  bucket = aws_s3_bucket.kidney_disease_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ECR Repository with unique name
resource "aws_ecr_repository" "kidney_disease_classifier" {
  name                 = "kidney-disease-classifier-${random_string.resource_suffix.result}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM Role for Batch Jobs with unique name
resource "aws_iam_role" "batch_job_role" {
  name = "BatchJobRole-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "batch_job_s3_policy" {
  name = "BatchJobS3Policy-${random_string.resource_suffix.result}"
  role = aws_iam_role.batch_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:HeadBucket",
          "s3:HeadObject",
          "s3:GetBucketLocation" 
        ]
        Resource = [
          aws_s3_bucket.kidney_disease_bucket.arn,
          "${aws_s3_bucket.kidney_disease_bucket.arn}/*"
        ]
      }
    ]
  })
}

# ECS Task Execution Role (NEW - MISSING FROM ORIGINAL)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (NEW - MISSING FROM ORIGINAL)
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECS Task Role Policy for S3 and Batch access
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecsTaskRolePolicy-${random_string.resource_suffix.result}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:HeadBucket",
          "s3:HeadObject"
        ]
        Resource = [
          aws_s3_bucket.kidney_disease_bucket.arn,
          "${aws_s3_bucket.kidney_disease_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "batch:SubmitJob",
          "batch:DescribeJobs",
          "batch:ListJobs",
          "batch:DescribeComputeEnvironments" 
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC and Networking
resource "aws_vpc" "batch_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "batch-vpc-${random_string.resource_suffix.result}"
  }
}

resource "aws_internet_gateway" "batch_igw" {
  vpc_id = aws_vpc.batch_vpc.id

  tags = {
    Name = "batch-igw-${random_string.resource_suffix.result}"
  }
}

resource "aws_subnet" "batch_subnet" {
  vpc_id                  = aws_vpc.batch_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "batch-subnet-${random_string.resource_suffix.result}"
  }
}

resource "aws_route_table" "batch_route_table" {
  vpc_id = aws_vpc.batch_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.batch_igw.id
  }

  tags = {
    Name = "batch-route-table-${random_string.resource_suffix.result}"
  }
}

resource "aws_route_table_association" "batch_route_table_association" {
  subnet_id      = aws_subnet.batch_subnet.id
  route_table_id = aws_route_table.batch_route_table.id
}

# Security Group
resource "aws_security_group" "batch_security_group" {
  name_prefix = "batch-sg-${random_string.resource_suffix.result}-"
  vpc_id      = aws_vpc.batch_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "batch-security-group-${random_string.resource_suffix.result}"
  }
}

# Batch Compute Environment
resource "aws_batch_compute_environment" "gpu_compute_env" {
  compute_environment_name = "gpu-compute-env-${random_string.resource_suffix.result}"
  type                     = "MANAGED"
  state                    = "ENABLED"

  compute_resources {
    type                = "SPOT"
    allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"
    min_vcpus           = 0
    max_vcpus           = 256
    desired_vcpus       = 0

    instance_type = ["p3.2xlarge"]

    ec2_configuration {
      image_type = "ECS_AL2_NVIDIA"
    }

    subnets = [aws_subnet.batch_subnet.id]
    security_group_ids = [aws_security_group.batch_security_group.id]

    instance_role = aws_iam_instance_profile.ecs_instance_profile.arn

    tags = {
      Name = "batch-compute-instance-${random_string.resource_suffix.result}"
    }
  }

  service_role = aws_iam_role.batch_service_role.arn

  depends_on = [aws_iam_role_policy_attachment.batch_service_role_policy]
}

# Batch Job Queue
resource "aws_batch_job_queue" "gpu_job_queue" {
  name     = "gpu-job-queue-${random_string.resource_suffix.result}"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.gpu_compute_env.arn
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Additional IAM roles and policies for Batch with unique names
resource "aws_iam_role" "batch_service_role" {
  name = "AWSBatchServiceRole-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role" "spot_fleet_role" {
  name = "aws-ec2-spot-fleet-role-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "spotfleet.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "spot_fleet_role_policy" {
  role       = aws_iam_role.spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole-${random_string.resource_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile-${random_string.resource_suffix.result}"
  role = aws_iam_role.ecs_instance_role.name
}

# Outputs
output "s3_bucket_name" {
  value = aws_s3_bucket.kidney_disease_bucket.bucket
}

output "ecr_repository_url" {
  value = aws_ecr_repository.kidney_disease_classifier.repository_url
}

output "batch_job_queue_arn" {
  value = aws_batch_job_queue.gpu_job_queue.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
  description = "ARN of the ECS task execution role"
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
  description = "ARN of the ECS task role"
}

output "resource_suffix" {
  value = random_string.resource_suffix.result
  description = "Random suffix used for resource names"
}
# Add this to your outputs section in main.tf
output "batch_job_role_arn" {
  value = aws_iam_role.batch_job_role.arn
  description = "ARN of the Batch job role"
}

# Add these outputs to your terraform/main.tf file

# Additional outputs needed for deployment script
output "vpc_id" {
  value = aws_vpc.batch_vpc.id
  description = "VPC ID for the batch infrastructure"
}

output "subnet_id" {
  value = aws_subnet.batch_subnet.id
  description = "Subnet ID for ECS tasks"
}

output "security_group_id" {
  value = aws_security_group.batch_security_group.id
  description = "Security Group ID for ECS tasks"
}

# Also add a security group rule for Flask app port 8080
resource "aws_security_group_rule" "flask_app_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.batch_security_group.id
  description       = "Allow inbound traffic on port 8080 for Flask app"
}