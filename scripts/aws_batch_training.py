#!/usr/bin/env python3
"""
AWS Batch Training Script for Kidney Disease Classifier
This script runs the complete training pipeline in AWS Batch environment
"""

import os
import sys
import boto3
import logging
import argparse
from pathlib import Path

# Add src to path
sys.path.insert(0, '/app/src')
sys.path.insert(0, '/app')

from cnnClassifier import logger
from cnnClassifier.pipeline.stage01_data_ingestion import DataIngestionTrainingPipeline
from cnnClassifier.pipeline.stage02_prepare_base_model import PrepareBaseModelPipeline
from cnnClassifier.pipeline.stage03_training import TrainingPipeline
from cnnClassifier.pipeline.stage04_model_evaluation import EvaluateModelPipeline

def setup_aws_environment():
    """Setup AWS environment and DVC"""
    logger.info("Setting up AWS environment...")
    
    # Initialize S3 client
    s3_client = boto3.client('s3')
    
    # Get environment variables
    s3_bucket = os.getenv('S3_BUCKET', '')
    aws_region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
    
    if not s3_bucket:
        raise ValueError("S3_BUCKET environment variable not set")
    
    logger.info(f"Using S3 bucket: {s3_bucket}")
    logger.info(f"AWS region: {aws_region}")
    
    # Initialize DVC in the working directory
    if not os.path.exists('.dvc'):
        logger.info("Initializing DVC...")
        os.system("dvc init --no-scm")
    
    # Configure DVC for S3
    logger.info("Configuring DVC remote...")
    os.system(f"dvc remote add -d myremote s3://{s3_bucket}/dvc-cache -f")
    os.system(f"dvc remote modify myremote region {aws_region}")
    
    # Test DVC S3 connection
    result = os.system("dvc remote list")
    if result == 0:
        logger.info("✓ DVC remote configured successfully")
    else:
        logger.warning("⚠ DVC remote configuration may have issues")
    
    return s3_client, s3_bucket

def sync_data_from_s3(s3_client, s3_bucket):
    """Sync data from S3 using DVC"""
    logger.info("Syncing data from S3...")
    
    try:
        # First, try to sync config files directly
        logger.info("Syncing config files...")
        os.makedirs('config', exist_ok=True)
        try:
            s3_client.download_file(s3_bucket, 'config/config.yaml', 'config/config.yaml')
            logger.info("✓ Config files synced from S3")
        except Exception as e:
            logger.warning(f"Failed to sync config files: {e}")
        
        # Try DVC pull first
        logger.info("Attempting DVC pull...")
        result = os.system("dvc pull")
        
        if result != 0:
            logger.warning("DVC pull failed, attempting direct S3 sync...")
            
            # Fallback: direct S3 sync for critical directories
            os.makedirs('artifacts', exist_ok=True)
            os.makedirs('artifacts/data_ingestion', exist_ok=True)
            
            # List and sync artifacts
            try:
                paginator = s3_client.get_paginator('list_objects_v2')
                for page in paginator.paginate(Bucket=s3_bucket, Prefix='artifacts/'):
                    if 'Contents' in page:
                        for obj in page['Contents']:
                            key = obj['Key']
                            local_path = key
                            os.makedirs(os.path.dirname(local_path), exist_ok=True)
                            s3_client.download_file(s3_bucket, key, local_path)
                            logger.info(f"Downloaded: {key}")
            except Exception as e:
                logger.warning(f"Direct S3 sync also failed: {e}")
                logger.info("Proceeding with data ingestion to download fresh data...")
        else:
            logger.info("✓ DVC pull successful")
        
        logger.info("Data sync process completed")
        
    except Exception as e:
        logger.error(f"Error syncing data: {e}")
        logger.info("Will attempt to proceed with data ingestion...")

def sync_results_to_s3(s3_client, s3_bucket):
    """Sync training results back to S3"""
    logger.info("Syncing results to S3...")
    
    try:
        # Push using DVC first
        logger.info("Attempting DVC push...")
        result = os.system("dvc push")
        
        if result != 0:
            logger.warning("DVC push failed, attempting direct S3 sync...")
        
        # Always do direct sync for important files
        job_id = os.getenv('AWS_BATCH_JOB_ID', 'latest')
        
        # Sync model file
        if os.path.exists("model/model.h5"):
            try:
                s3_client.upload_file("model/model.h5", s3_bucket, f"models/model_{job_id}.h5")
                s3_client.upload_file("model/model.h5", s3_bucket, "model/model.h5")  # Latest model
                logger.info("✓ Model uploaded to S3")
            except Exception as e:
                logger.error(f"Failed to upload model: {e}")
        
        # Sync evaluation scores
        if os.path.exists("scores.json"):
            try:
                s3_client.upload_file("scores.json", s3_bucket, f"results/scores_{job_id}.json")
                s3_client.upload_file("scores.json", s3_bucket, "results/scores.json")  # Latest scores
                logger.info("✓ Scores uploaded to S3")
            except Exception as e:
                logger.error(f"Failed to upload scores: {e}")
        
        # Sync logs
        if os.path.exists("logs"):
            try:
                for root, dirs, files in os.walk("logs"):
                    for file in files:
                        local_path = os.path.join(root, file)
                        s3_key = f"logs/{job_id}/{file}"
                        s3_client.upload_file(local_path, s3_bucket, s3_key)
                logger.info("✓ Logs uploaded to S3")
            except Exception as e:
                logger.error(f"Failed to upload logs: {e}")
        
        # Sync artifacts
        if os.path.exists("artifacts"):
            try:
                for root, dirs, files in os.walk("artifacts"):
                    for file in files:
                        local_path = os.path.join(root, file)
                        s3_key = local_path
                        s3_client.upload_file(local_path, s3_bucket, s3_key)
                logger.info("✓ Artifacts uploaded to S3")
            except Exception as e:
                logger.error(f"Failed to upload artifacts: {e}")
        
        logger.info("Results sync completed successfully")
        
    except Exception as e:
        logger.error(f"Error syncing results: {e}")
        raise

def run_training_pipeline():
    """Run the complete training pipeline"""
    
    # Stage 1: Data Ingestion
    STAGE_NAME = "Data Ingestion Stage"
    try:
        logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
        data_ingestion = DataIngestionTrainingPipeline()
        data_ingestion.main()
        logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
    except Exception as e:
        logger.exception(e)
        raise e

    # Stage 2: Prepare Base Model
    STAGE_NAME = "Prepare Base Model Stage"
    try:
        logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
        prepare_base_model = PrepareBaseModelPipeline()
        prepare_base_model.main()
        logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
    except Exception as e:
        logger.exception(e)
        raise e

    # Stage 3: Training
    STAGE_NAME = "Training Model Stage"
    try:
        logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
        training_model = TrainingPipeline()
        training_model.main()
        logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
    except Exception as e:
        logger.exception(e)
        raise e

    # Stage 4: Evaluation
    STAGE_NAME = "Evaluate Model Stage"
    try:
        logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
        eval_model = EvaluateModelPipeline()
        eval_model.main()
        logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
    except Exception as e:
        logger.exception(e)
        raise e

def main():
    """Main function for AWS Batch training"""
    parser = argparse.ArgumentParser(description='AWS Batch Training Script')
    parser.add_argument('--input-data-path', type=str, help='S3 path for input data')
    parser.add_argument('--output-model-path', type=str, help='S3 path for output model')
    parser.add_argument('--config-path', type=str, help='S3 path for config files')
    
    args = parser.parse_args()
    
    logger.info("🚀 Starting AWS Batch training job...")
    logger.info(f"Job ID: {os.getenv('AWS_BATCH_JOB_ID', 'unknown')}")
    logger.info(f"Job Queue: {os.getenv('AWS_BATCH_JQ_NAME', 'unknown')}")
    logger.info(f"Python path: {sys.path}")
    
    # Log GPU information
    try:
        import tensorflow as tf
        logger.info(f"TensorFlow version: {tf.__version__}")
        logger.info(f"GPU Available: {tf.config.list_physical_devices('GPU')}")
        logger.info(f"CUDA Available: {tf.test.is_built_with_cuda()}")
    except Exception as e:
        logger.warning(f"Could not get GPU info: {e}")
    
    try:
        # Setup AWS environment
        s3_client, s3_bucket = setup_aws_environment()
        
        # Sync data from S3
        sync_data_from_s3(s3_client, s3_bucket)
        
        # Run training pipeline
        run_training_pipeline()
        
        # Sync results back to S3
        sync_results_to_s3(s3_client, s3_bucket)
        
        logger.info("🎉 Training job completed successfully!")
        
    except Exception as e:
        logger.error(f"❌ Training job failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()