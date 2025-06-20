# Kidney-Disease-Classification-MLflow-DVC
## Workflows

1. Update config.yaml
2. Update secrets.yaml [Optional]
3. Update params.yaml
4. Update the entity
5. Update the configuration manager in src config
6. Update the components.
7. Update the pipeline
8. Update the main.py
9. Update the dvc.yaml
10. app.py

## How to run?
# STEPS:
## Clone the repository

### STEP 01- Create a conda environment after opening the repository
```bash
conda create -n cnncls python=3.8 -y
conda activate cnncls
```
### STEP 02- install the requirements
```bash
pip install -r requirements.txt
```
### Finally run the following command
```bash
python app.py
```
Now,

open up you local host and port
## MLflow
### Documentation

### MLflow tutorial

MLFLOW_TRACKING_URI=https://dagshub.com/fakhar-iqbal/Kidney-Disease-Classification-MLFlow-DVC.mlflow
MLFLOW_TRACKING_USERNAME=fakhar-iqbal
MLFLOW_TRACKING_PASSWORD=6913d694a6121a1db4dc642442e78536fe3fe5ed
python script.py

Run this to export as env variables:
```bash
set MLFLOW_TRACKING_URI=https://dagshub.com/fakhar-iqbal/Kidney-Disease-Classification-MLFlow-DVC.mlflow

set MLFLOW_TRACKING_USERNAME=fakhar-iqbal 

set MLFLOW_TRACKING_PASSWORD= 6913d694a6121a1db4dc642442e78536fe3fe5ed
```

## DVC cmds
```
dvc init
dvc repro
dvc dag
```

## About MLflow & DVC

MLflow

 - Its Production Grade
 - Trace all of your expriements
 - Logging & taging your model

DVC 

 - Its very lite weight for POC only
 - lite weight expriements tracker
 - It can perform Orchestration (Creating Pipelines)

# AWS-CICD-Deployment-with-Github-Actions

## 1. Login to AWS console.

## 2. Create IAM user for deployment

    #with specific access

    1. EC2 access : It is virtual machine

    2. ECR: Elastic Container registry to save your docker image in aws

    #Description: About the deployment

    1. Build docker image of the source code

    2. Push your docker image to ECR

    3. Launch Your EC2 

    4. Pull Your image from ECR in EC2

    5. Lauch your docker image in EC2

    #Policy:

    1. AmazonEC2ContainerRegistryFullAccess

    2. AmazonEC2FullAccess

    
## 3. Create ECR repo to store/save docker image
    - Save the URI: 66441898.eu-no-1.amazonaws.com/kidney_app

    
## 4. Create EC2 machine (Ubuntu) 

## 5. Open EC2 and Install docker in EC2 Machine:
    
    
    #optinal

    sudo apt-get update -y

    sudo apt-get upgrade
    
    #required

    sudo apt install docker.io -y
    sudo usermod -aG docker $USER

    newgrp docker
    
# 6. Configure EC2 as self-hosted runner:
    setting>actions>runner>new self hosted runner> choose os> then run command one by one


# 7. Setup github secrets:

    AWS_ACCESS_KEY_ID=

    AWS_SECRET_ACCESS_KEY=

    AWS_REGION = us-east-1

    AWS_ECR_LOGIN_URI = demo>>  566373416292.dkr.ecr.ap-south-1.amazonaws.com

    ECR_REPOSITORY_NAME = simple-app

---

## **Detailed End-to-End Cycle: Cloud MLOps Deployment & Training**

### 1. **Infrastructure Provisioning with Terraform**
- Write Terraform scripts to define AWS resources: S3 (for data/models), ECR (for Docker images), Batch (for training), ECS Fargate (for API), IAM roles, VPC, etc.
- Run `terraform init` and `terraform apply` to create/update all resources automatically.

### 2. **Data & Model Versioning with DVC**
- Use DVC to track datasets, models, and pipeline steps.
- Configure DVC remote to S3 for cloud storage.
- Use `dvc add`, `dvc push`, and `dvc pull` to sync data and models between local and S3.

### 3. **Containerization with Docker**
- Write a `Dockerfile` to package your code, dependencies, and scripts.
- Build the Docker image locally.
- Authenticate with AWS ECR and push the image using:
  ```bash
  aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ECR_URI>
  docker tag kidney-ml:latest <ECR_URI>:latest
  docker push <ECR_URI>:latest
  ```

### 4. **CI/CD Automation with GitHub Actions and deploy.sh**
- Use GitHub Actions to automate:
  - Running `deploy.sh` for infrastructure, image build, and deployment.
  - Setting up secrets for AWS credentials and ECR info.
- `deploy.sh` script typically:
  - Runs Terraform to provision/update infra.
  - Builds and pushes Docker image to ECR.
  - Registers/updates AWS Batch job definitions.
  - Deploys Flask API to ECS Fargate.

### 5. **Training on AWS Batch**
- The Flask API exposes a `/train` endpoint.
- When triggered, it uses `boto3` to submit a job to AWS Batch, specifying the Docker image and command.
- AWS Batch launches a container on a GPU/CPU instance, running `scripts/aws_batch_training.py`.
- The script:
  - Pulls data and pipeline from S3 using DVC.
  - Trains the model and saves outputs.
  - Pushes results (model, metrics) back to S3 via DVC.

### 6. **Model Serving with ECS Fargate**
- The Flask API is deployed as a container on ECS Fargate.
- Exposes endpoints for inference, training, and job status.
- ECS Fargate handles scaling and availability.

### 7. **Monitoring and Management**
- Use Flask endpoints to check training job status and retrieve results.
- All artifacts and logs are stored in S3 for traceability.

---

**Summary Table**

| Tool         | Responsibility                                                                 |
|--------------|-------------------------------------------------------------------------------|
| **Terraform**| Infrastructure as code: AWS Batch, S3, ECR, ECS, IAM, networking              |
| **DVC**      | Data & artifact versioning, pipeline orchestration, S3 sync                   |
| **Docker**   | Packaging code and dependencies for reproducible execution                    |
| **AWS Batch**| Scalable, GPU-based model training                                            |
| **ECS Fargate**| Hosting Flask API for inference and job management                          |
| **GitHub Actions / Bash** | CI/CD automation: build, push, deploy, infra provisioning        |
| **Flask**    | REST API for training, inference, and job status                              |
| **boto3**    | AWS SDK for Python: interacts with Batch, S3, etc.                            |

---

**This cycle ensures your ML system is fully automated, reproducible, and scalable on AWS cloud.**

