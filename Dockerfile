# FROM python:3.8-slim-buster

# RUN apt update -y && apt install awscli -y
# WORKDIR /app

# COPY . /app
# RUN pip install -r requirements.txt

# CMD ["python3", "app.py"]


# Multi-stage build for training and serving
# FROM python:3.8-slim-buster as base

# # Install system dependencies
# RUN apt-get update -y && \
#     apt-get install -y awscli git wget && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# WORKDIR /app

# # Copy requirements first for better caching
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# # Copy source code
# COPY . .

# # Training stage - for AWS Batch GPU training
# FROM base as training
# RUN pip install dvc[s3]
# CMD ["python", "main.py"]
# Use a more stable base image with CUDA support



FROM tensorflow/tensorflow:2.13.0-gpu
ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH="/app/src"
RUN apt-get update -y && \
    apt-get install -y \
        awscli \
        git \
        wget \
        curl \
        unzip \
        build-essential \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt setup.py README.md /app/
COPY src /app/src
RUN python -m pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir \
    boto3 \
    botocore \
    s3fs \
    aiobotocore[boto3]==2.10.0 \
    s3transfer \
    dvc[s3]
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install -e .
COPY . /app
RUN mkdir -p /app/artifacts /app/logs /app/model /app/config
COPY scripts/aws_batch_training.py /app/aws_batch_training.py
RUN find /app -name "*.py" -exec chmod +x {} \;
RUN python -c "import dvc; print('✅ DVC version:', dvc.__version__)"
RUN python -c "import boto3; print('✅ Boto3 version:', boto3.__version__)"
RUN dvc version

EXPOSE 8080

CMD ["python", "app.py"]
