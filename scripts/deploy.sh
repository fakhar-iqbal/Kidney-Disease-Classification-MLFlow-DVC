# #!/bin/bash

# # AWS Deployment Script for Kidney Disease Classifier
# set -e

# echo "🚀 Starting AWS Deployment Process..."

# # Configuration
# AWS_REGION="us-east-1"
# PROJECT_NAME="kidney-disease-classifier"

# # Colors for output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m' # No Color



# print_status() {
#     echo -e "${GREEN}[INFO]${NC} $1"
# }

# print_warning() {
#     echo -e "${YELLOW}[WARNING]${NC} $1"
# }

# print_error() {
#     echo -e "${RED}[ERROR]${NC} $1"
# }

# # Function to check if AWS CLI is configured
# check_aws_cli() {
#     print_status "Checking AWS CLI configuration..."
#     if ! aws sts get-caller-identity > /dev/null 2>&1; then
#         print_error "AWS CLI is not configured. Please run 'aws configure' first."
#         exit 1
#     fi
#     print_status "AWS CLI is configured ✓"
# }

# # Function to get AWS Account ID
# get_account_id() {
#     AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#     print_status "AWS Account ID: $AWS_ACCOUNT_ID"
# }

# # Function to deploy infrastructure with Terraform
# deploy_infrastructure() {
#     print_status "Deploying infrastructure with Terraform..."
    
#     cd terraform
    
#     # Initialize Terraform
#     print_status "Initializing Terraform..."
#     terraform init
    
#     # Plan deployment
#     print_status "Creating Terraform plan..."
#     terraform plan -out=tfplan
    
#     # Apply deployment
#     print_status "Applying Terraform configuration..."
#     terraform apply tfplan
    
#     # Get outputs
#     S3_BUCKET=$(terraform output -raw s3_bucket_name)
#     ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
#     BATCH_JOB_QUEUE=$(terraform output -raw batch_job_queue_arn)
    
#     print_status "Infrastructure deployed successfully ✓"
#     print_status "S3 Bucket: $S3_BUCKET"
#     print_status "ECR Repository: $ECR_REPO_URL"
#     print_status "Batch Job Queue: $BATCH_JOB_QUEUE"
    
#     cd ..
# }

# # Function to build and push Docker image
# build_and_push_image() {
#     print_status "Building and pushing Docker image..."
    
#     # Get ECR login token
#     aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
    
#     # Build Docker image
#     print_status "Building Docker image..."
#     docker build -t $PROJECT_NAME .
    
#     # Tag image for ECR
#     docker tag $PROJECT_NAME:latest $ECR_REPO_URL:latest
    
#     # Push image to ECR
#     print_status "Pushing image to ECR..."
#     docker push $ECR_REPO_URL:latest
    
#     print_status "Docker image pushed successfully ✓"
# }

# # Function to setup DVC with S3
# setup_dvc_s3() {
#     print_status "Setting up DVC with S3..."

#     # Check if DVC is installed
#     if ! command -v dvc &> /dev/null; then
#         print_warning "DVC not found. Installing DVC..."
#         pip install dvc
#     fi

#     # Check if dvc-s3 plugin is installed
#     if ! pip show dvc-s3 &> /dev/null; then
#         print_warning "dvc-s3 plugin not found. Installing..."
#         pip install dvc-s3
#     fi

#     # Print DVC version
#     DVC_VERSION=$(dvc --version 2>/dev/null)
#     print_status "DVC version: $DVC_VERSION"

#     # Print dvc-s3 plugin version
#     DVC_S3_VERSION=$(pip show dvc-s3 2>/dev/null | grep Version | awk '{print $2}')
#     print_status "dvc-s3 plugin version: ${DVC_S3_VERSION:-Not Found}"

#     # Ensure we're in a DVC repo
#     if ! dvc status &> /dev/null; then
#         print_warning "Not inside a DVC repo. Initializing DVC..."
#         dvc init
#         git add .dvc .dvcignore
#         git commit -m "Initialize DVC repo" || print_warning "Git commit skipped (maybe nothing changed)"
#     fi

#     # Configure DVC remote
#     print_status "Configuring remote storage for DVC..."
#     dvc remote add -f -d myremote s3://$S3_BUCKET/dvc-cache
#     dvc remote modify myremote region $AWS_REGION

#     # Push data
#     print_status "Pushing data to S3 via DVC..."
#     dvc push

#     print_status "DVC setup completed ✓"
# }


# # Function to create Batch job definition
# create_batch_job_definition() {
#     print_status "Creating AWS Batch job definition..."
    
#     # Replace placeholders in job definition
#     sed -e "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" \
#         -e "s/YOUR_REGION/$AWS_REGION/g" \
#         -e "s|your-kidney-disease-bucket|$S3_BUCKET|g" \
#         aws-configs/aws-batch-job-definition.json > temp-job-definition.json
    
#     # Create job definition
#     aws batch register-job-definition --cli-input-json file://temp-job-definition.json
    
#     # Clean up temp file
#     rm temp-job-definition.json
    
#     print_status "Batch job definition created ✓"
# }

# # Function to deploy Flask app to ECS Fargate
# # Function to deploy Flask app to ECS Fargate
# deploy_flask_app() {
#     print_status "Deploying Flask application to ECS Fargate..."
    
#     # Get role ARNs from Terraform outputs
#     cd terraform
#     ECS_EXECUTION_ROLE_ARN=$(terraform output -raw ecs_task_execution_role_arn)
#     ECS_TASK_ROLE_ARN=$(terraform output -raw ecs_task_role_arn)
#     cd ..
    
#     print_status "Using ECS Execution Role: $ECS_EXECUTION_ROLE_ARN"
#     print_status "Using ECS Task Role: $ECS_TASK_ROLE_ARN"
    
#     # Create ECS cluster
#     aws ecs create-cluster --cluster-name kidney-disease-app-cluster
    
#     # Create task definition for Flask app
#     cat > flask-task-definition.json << EOF
# {
#   "family": "kidney-disease-flask-app",
#   "networkMode": "awsvpc",
#   "requiresCompatibilities": ["FARGATE"],
#   "cpu": "256",
#   "memory": "512",
#   "executionRoleArn": "$ECS_EXECUTION_ROLE_ARN",
#   "taskRoleArn": "$ECS_TASK_ROLE_ARN",
#   "containerDefinitions": [
#     {
#       "name": "flask-app",
#       "image": "$ECR_REPO_URL:latest",
#       "portMappings": [
#         {
#           "containerPort": 8080,
#           "protocol": "tcp"
#         }
#       ],
#       "environment": [
#         {
#           "name": "AWS_DEFAULT_REGION",
#           "value": "$AWS_REGION"
#         },
#         {
#           "name": "S3_BUCKET",
#           "value": "$S3_BUCKET"
#         },
#         {
#           "name": "BATCH_JOB_QUEUE",
#           "value": "$BATCH_JOB_QUEUE"
#         }
#       ],
#       "logConfiguration": {
#         "logDriver": "awslogs",
#         "options": {
#           "awslogs-group": "/ecs/kidney-disease-flask-app",
#           "awslogs-region": "$AWS_REGION",
#           "awslogs-stream-prefix": "ecs"
#         }
#       }
#     }
#   ]
# }
# EOF

#     # Create CloudWatch log group
#     aws logs create-log-group --log-group-name ecs/kidney-disease-flask-app --region $AWS_REGION || true
    
#     # Register task definition
#     aws ecs register-task-definition --cli-input-json file://flask-task-definition.json
    
#     # Create ECS service
#     aws ecs create-service \
#         --cluster kidney-disease-app-cluster \
#         --service-name kidney-disease-service \
#         --task-definition kidney-disease-flask-app \
#         --desired-count 1 \
#         --launch-type FARGATE \
#         --network-configuration "awsvpcConfiguration={subnets=[$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=batch-vpc" --query 'Vpcs[0].VpcId' --output text)" --query 'Subnets[0].SubnetId' --output text)],securityGroups=[$(aws ec2 describe-security-groups --filters "Name=group-name,Values=batch-sg*" --query 'SecurityGroups[0].GroupId' --output text)],assignPublicIp=ENABLED}"
    
#     print_status "Flask application deployed to ECS Fargate ✓"
    
#     # Clean up
#     rm flask-task-definition.json
# }
# # Main deployment function
# main() {
#     print_status "=== AWS Kidney Disease Classifier Deployment ==="
    
#     check_aws_cli
#     get_account_id
#     deploy_infrastructure
#     build_and_push_image
#     setup_dvc_s3
#     create_batch_job_definition
#     deploy_flask_app
    
#     print_status "🎉 Deployment completed successfully!"
#     print_status "Your application is now running on AWS!"
#     print_warning "Note: It may take a few minutes for the ECS service to be fully available."
# }

# # Run main function
# main


#!/bin/bash

# AWS Deployment Script for Kidney Disease Classifier
set -e

echo "🚀 Starting AWS Deployment Process..."

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="kidney-disease-classifier"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    print_status "Checking AWS CLI configuration..."
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_status "AWS CLI is configured ✓"
}

# Function to get AWS Account ID
get_account_id() {
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Get outputs
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
    BATCH_JOB_QUEUE=$(terraform output -raw batch_job_queue_arn)
    VPC_ID=$(terraform output -raw vpc_id)
    SUBNET_ID=$(terraform output -raw subnet_id)
    SECURITY_GROUP_ID=$(terraform output -raw security_group_id)
    
    print_status "Infrastructure deployed successfully ✓"
    print_status "S3 Bucket: $S3_BUCKET"
    print_status "ECR Repository: $ECR_REPO_URL"
    print_status "Batch Job Queue: $BATCH_JOB_QUEUE"
    
    cd ..
}

# Function to build and push Docker image
build_and_push_image() {
    print_status "Building and pushing Docker image..."
    
    # Verify Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in current directory!"
        exit 1
    fi
    
    # Verify training script exists in scripts folder
    if [ ! -f "scripts/aws_batch_training.py" ]; then
        print_error "aws_batch_training.py not found in scripts/ folder!"
        exit 1
    fi
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t $PROJECT_NAME .
    
    # Tag image for ECR
    docker tag $PROJECT_NAME:latest $ECR_REPO_URL:latest
    
    # Push image to ECR
    print_status "Pushing image to ECR..."
    docker push $ECR_REPO_URL:latest
    
    print_status "Docker image pushed successfully ✓"
}

# Function to setup DVC with S3
setup_dvc_s3() {
    print_status "Setting up DVC with S3..."

    # Check if DVC is installed
    if ! command -v dvc &> /dev/null; then
        print_warning "DVC not found. Installing DVC..."
        pip install dvc dvc-s3
    fi

    # Ensure we're in a DVC repo
    if [ ! -d ".dvc" ]; then
        print_warning "Not inside a DVC repo. Initializing DVC..."
        dvc init --no-scm
    fi

    # Configure DVC remote
    print_status "Configuring remote storage for DVC..."
    dvc remote add -f -d myremote s3://$S3_BUCKET/dvc-cache
    dvc remote modify myremote region $AWS_REGION

    # Push data if dvc files exist
    if ls *.dvc 1> /dev/null 2>&1; then
        print_status "Pushing data to S3 via DVC..."
        dvc push
    else
        print_warning "No .dvc files found. Ensure your data is tracked with DVC."
    fi

    print_status "DVC setup completed ✓"
}

# Function to create Batch job definition
# create_batch_job_definition() {
#     print_status "Creating AWS Batch job definition..."
    
#     # Create job definition JSON
#     cat > temp-job-definition.json << EOF
# {
#     "jobDefinitionName": "kidney-disease-training-job",
#     "type": "container",
#     "containerProperties": {
#         "image": "$ECR_REPO_URL:latest",
#         "vcpus": 4,
#         "memory": 8192,
#         "resourceRequirements": [
#             {
#                 "type": "GPU",
#                 "value": "1"
#             }
#         ],
#         "command": [
#             "python3",
#             "/app/scripts/aws_batch_training.py"
#         ],
#         "environment": [
#             {
#                 "name": "AWS_DEFAULT_REGION",
#                 "value": "$AWS_REGION"
#             },
#             {
#                 "name": "S3_BUCKET",
#                 "value": "$S3_BUCKET"
#             }
#         ],
#         "mountPoints": [],
#         "volumes": [],
#         "ulimits": []
#     },
#     "timeout": {
#         "attemptDurationSeconds": 7200
#     },
#     "retryStrategy": {
#         "attempts": 1
#     }
# }
# EOF
    
#     # Create job definition
#     aws batch register-job-definition --cli-input-json file://temp-job-definition.json
    
#     # Clean up temp file
#     rm temp-job-definition.json
    
#     print_status "Batch job definition created ✓"
# }

# Function to create Batch job definition
create_batch_job_definition() {
    print_status "Creating AWS Batch job definition..."
    
    # Get the Batch job role ARN from Terraform outputs
    cd terraform
    BATCH_JOB_ROLE_ARN=$(terraform output -raw batch_job_role_arn)
    cd ..
    
    # Create job definition JSON
    cat > temp-job-definition.json << EOF
{
    "jobDefinitionName": "kidney-disease-training-job",
    "type": "container",
    "containerProperties": {
        "image": "$ECR_REPO_URL:latest",
        "vcpus": 4,
        "memory": 8192,
        "jobRoleArn": "$BATCH_JOB_ROLE_ARN",
        "resourceRequirements": [
            {
                "type": "GPU",
                "value": "1"
            }
        ],
        "command": [
            "python3",
            "/app/scripts/aws_batch_training.py"
        ],
        "environment": [
            {
                "name": "AWS_DEFAULT_REGION",
                "value": "$AWS_REGION"
            },
            {
                "name": "S3_BUCKET",
                "value": "$S3_BUCKET"
            },
            {
                "name": "PYTHONPATH",
                "value": "/app/src:/app"
            },
            {
                "name": "DVC_CACHE_TYPE",
                "value": "s3"
            }
            
        ],
        "mountPoints": [],
        "volumes": [],
        "ulimits": []
    },
    "timeout": {
        "attemptDurationSeconds": 7200
    },
    "retryStrategy": {
        "attempts": 1
    }
}
EOF
    
    # Create job definition
    aws batch register-job-definition --cli-input-json file://temp-job-definition.json
    
    # Clean up temp file
    rm temp-job-definition.json
    
    print_status "Batch job definition created ✓"
}

# Function to deploy Flask app to ECS Fargate
deploy_flask_app() {
    print_status "Deploying Flask application to ECS Fargate..."
    
    # Get role ARNs from Terraform outputs
    cd terraform
    ECS_EXECUTION_ROLE_ARN=$(terraform output -raw ecs_task_execution_role_arn)
    ECS_TASK_ROLE_ARN=$(terraform output -raw ecs_task_role_arn)
    SUBNET_ID=$(terraform output -raw subnet_id)
    SECURITY_GROUP_ID=$(terraform output -raw security_group_id)
    cd ..
    
    print_status "Using ECS Execution Role: $ECS_EXECUTION_ROLE_ARN"
    print_status "Using ECS Task Role: $ECS_TASK_ROLE_ARN"
    
    # Create ECS cluster
    aws ecs create-cluster --cluster-name kidney-disease-app-cluster || true
    
    # Create task definition for Flask app
    cat > flask-task-definition.json << EOF
{
  "family": "kidney-disease-flask-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "$ECS_EXECUTION_ROLE_ARN",
  "taskRoleArn": "$ECS_TASK_ROLE_ARN",
  "containerDefinitions": [
    {
      "name": "flask-app",
      "image": "$ECR_REPO_URL:latest",
      "command": ["python3", "app.py"],
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "AWS_DEFAULT_REGION",
          "value": "$AWS_REGION"
        },
        {
          "name": "S3_BUCKET",
          "value": "$S3_BUCKET"
        },
        {
          "name": "BATCH_JOB_QUEUE",
          "value": "$BATCH_JOB_QUEUE"
        },
        {
          "name": "BATCH_JOB_DEFINITION",
          "value": "kidney-disease-training-job"
        },
        {
          "name": "FLASK_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/kidney-disease-flask-app",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

    # Create CloudWatch log group
    aws logs create-log-group --log-group-name /ecs/kidney-disease-flask-app --region $AWS_REGION 2>/dev/null || true
    
    # Register task definition
    aws ecs register-task-definition --cli-input-json file://flask-task-definition.json
    
    # Create ECS service
    aws ecs create-service \
        --cluster kidney-disease-app-cluster \
        --service-name kidney-disease-service \
        --task-definition kidney-disease-flask-app \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" || true
    
    print_status "Flask application deployed to ECS Fargate ✓"
    
    # Clean up
    rm flask-task-definition.json
}

# Main deployment function
main() {
    print_status "=== AWS Kidney Disease Classifier Deployment ==="
    
    check_aws_cli
    get_account_id
    deploy_infrastructure
    build_and_push_image
    setup_dvc_s3
    create_batch_job_definition
    deploy_flask_app
    
    print_status "🎉 Deployment completed successfully!"
    print_status "Your Flask API is now running on AWS ECS Fargate!"
    print_status "Training jobs will run on AWS Batch with GPU spot instances!"
    print_warning "Note: It may take a few minutes for the ECS service to be fully available."
    
    # Get ECS service info
    print_status "Getting ECS service status..."
    aws ecs describe-services --cluster kidney-disease-app-cluster --services kidney-disease-service --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' --output table
}

# Run main function
main