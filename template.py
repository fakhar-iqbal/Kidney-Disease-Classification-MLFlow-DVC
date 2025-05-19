import os
import logging
from pathlib import Path

#logging string
logging.basicConfig(level=logging.INFO, format = '[%(asctime)s]: %(message)s:')

project_name = 'cnnClassifier'

list_of_files = [
    ".github/workflows/.gitkeep",
    f"src/{project_name}/__init__.py",
    f"src/{project_name}/components/__init__.py",
    f"src/{project_name}/utils/__init__.py",
    f"src/{project_name}/config/__init__.py",
    f"src/{project_name}/config/configuration.py",
    f"src/{project_name}/pipeline/__init__.py",
    f"src/{project_name}/entity/__init__.py",
    f"src/{project_name}/constants/__init__.py",
    f"src/{project_name}/logging/__init__.py",
    "config/config.yaml",
    "dvc.yaml",
    "params.yaml",
    "requirements.txt",
    "setup.py",
    "research/trials.ipynb",
    "templates/index.html",
]


for file_path in list_of_files:
    filepath = Path(file_path)
    
    filedir, filename = os.path.split(filepath)
    
    if filedir!= "":
        os.makedirs(filedir, exist_ok=True)
        logging.info(f"Creating directory: {filedir} for file: {filename}")
    
    if not os.path.exists(filepath) or(os.path.exists(filepath) and os.path.getsize(filepath)==0):
        with open(filepath, 'w') as f:
            pass
        logging.info(f"Creating file: {filepath} for file: {filename}")
    else:
        logging.info(f"File already exists: {filepath} for file: {filename}")