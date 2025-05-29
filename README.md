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

cmd
mlflow ui
dagshub
dagshub

MLFLOW_TRACKING_URI=https://dagshub.com/entbappy/Kidney-Disease-Classification-MLflow-DVC.mlflow
MLFLOW_TRACKING_USERNAME=entbappy
MLFLOW_TRACKING_PASSWORD=6824692c47a369aa6f9eac5b10041d5c8edbcef0
python script.py

Run this to export as env variables:
```bash
set MLFLOW_TRACKING_URI=https://dagshub.com/fakhar-iqbal/Kidney-Disease-Classification-MLFlow-DVC.mlflow

set MLFLOW_TRACKING_USERNAME=fakhar-iqbal 

set MLFLOW_TRACKING_PASSWORD= 6913d694a6121a1db4dc642442e78536fe3fe5ed
```