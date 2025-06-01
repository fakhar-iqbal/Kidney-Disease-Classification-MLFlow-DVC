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

