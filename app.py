# # from flask import Flask, request, jsonify, render_template
# # import os
# # from flask_cors import CORS, cross_origin
# # from cnnClassifier.utils.common import decodeImage
# # from cnnClassifier.pipeline.prediction import PredictionPipeline

# # # initialize flask

# # os.putenv('LANG', 'en_US.UTF-8')
# # os.putenv('LC_ALL', 'en_US.UTF-8')

# # app = Flask(__name__)
# # CORS(app)

# # class ClientApp:
# #     def __init__(self):
# #         self.filename = "inputImage.jpg"
# #         self.classifier = PredictionPipeline(self.filename)
        
# # @app.route("/", methods=['GET'])
# # @cross_origin()
# # def home():
# #     return render_template('index.html')

# # @app.route("/train", methods=['GET','POST'])
# # @cross_origin()
# # def trainRoute():
# #     os.system("dvc repro")
# #     return "Training completed successfully"

# # @app.route("/predict", methods=['POST'])
# # @cross_origin()
# # def predictionRoute():
# #     image = request.json['image']
# #     decodeImage(image, clApp.filename)
# #     result = clApp.classifier.predict()
# #     return jsonify(result)

# # if __name__ == "__main__":
# #     clApp = ClientApp()
    
# #     # app.run(host='0.0.0.0', port= 8080)
# #     app.run(host='0.0.0.0', port = 8080)
# from flask import Flask, request, jsonify, render_template
# import os
# import boto3
# import json
# from flask_cors import CORS, cross_origin
# from cnnClassifier.utils.common import decodeImage
# from cnnClassifier.pipeline.prediction import PredictionPipeline

# # Initialize flask
# os.putenv('LANG', 'en_US.UTF-8')
# os.putenv('LC_ALL', 'en_US.UTF-8')

# app = Flask(__name__)
# CORS(app)

# # AWS Configuration
# AWS_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
# S3_BUCKET = os.getenv('S3_BUCKET', '')
# BATCH_JOB_QUEUE = os.getenv('BATCH_JOB_QUEUE', '')
# BATCH_JOB_DEFINITION = os.getenv('BATCH_JOB_DEFINITION', 'kidney-disease-training-job')

# # Initialize AWS clients
# batch_client = boto3.client('batch', region_name=AWS_REGION)
# s3_client = boto3.client('s3', region_name=AWS_REGION)

# class ClientApp:
#     def __init__(self):
#         self.filename = "inputImage.jpg"
#         self.classifier = PredictionPipeline(self.filename)

# @app.route("/", methods=['GET'])
# @cross_origin()
# def home():
#     return render_template('index.html')

# @app.route("/health", methods=['GET'])
# @cross_origin()
# def health_check():
#     return jsonify({"status": "healthy", "service": "kidney-disease-classifier"})

# @app.route("/train", methods=['GET', 'POST'])
# @cross_origin()
# def trainRoute():
#     """
#     Trigger training using AWS Batch with Spot GPU instances
#     """
#     try:
#         # Submit job to AWS Batch
#         response = batch_client.submit_job(
#             jobName=f'kidney-disease-training-{int(os.urandom(4).hex(), 16)}',
#             jobQueue=BATCH_JOB_QUEUE,
#             jobDefinition=BATCH_JOB_DEFINITION,
#             parameters={
#                 'inputDataPath': f's3://{S3_BUCKET}/data/',
#                 'outputModelPath': f's3://{S3_BUCKET}/model/',
#                 'configPath': f's3://{S3_BUCKET}/config/'
#             },
#             timeout={
#                 'attemptDurationSeconds': 7200  # 2 hours timeout
#             }
#         )
        
#         job_id = response['jobId']
#         job_name = response['jobName']
        
#         return jsonify({
#             "status": "success",
#             "message": f"Training job submitted successfully",
#             "job_id": job_id,
#             "job_name": job_name,
#             "note": "Training is running on AWS Batch with Spot GPU instances. Check /train-status/<job_id> for progress."
#         })
        
#     except Exception as e:
#         return jsonify({
#             "status": "error",
#             "message": f"Failed to submit training job: {str(e)}"
#         }), 500

# @app.route("/train-status/<job_id>", methods=['GET'])
# @cross_origin()
# def get_training_status(job_id):
#     """
#     Get training job status from AWS Batch
#     """
#     try:
#         response = batch_client.describe_jobs(jobs=[job_id])
        
#         if not response['jobs']:
#             return jsonify({
#                 "status": "error",
#                 "message": "Job not found"
#             }), 404
        
#         job = response['jobs'][0]
#         job_status = job['jobStatus']
        
#         result = {
#             "job_id": job_id,
#             "status": job_status,
#             "job_name": job['jobName'],
#             "created_at": job['createdAt'],
#         }
        
#         if 'startedAt' in job:
#             result['started_at'] = job['startedAt']
        
#         if 'stoppedAt' in job:
#             result['stopped_at'] = job['stoppedAt']
            
#         if 'statusReason' in job:
#             result['status_reason'] = job['statusReason']
            
#         # If job is completed, check for results in S3
#         if job_status == 'SUCCEEDED':
#             try:
#                 # Check if model exists in S3
#                 s3_client.head_object(Bucket=S3_BUCKET, Key=f'model/model_{job_id}.h5')
#                 result['model_available'] = True
#                 result['model_s3_path'] = f's3://{S3_BUCKET}/model/model_{job_id}.h5'
#             except:
#                 result['model_available'] = False
                
#         return jsonify(result)
        
#     except Exception as e:
#         return jsonify({
#             "status": "error",
#             "message": f"Failed to get job status: {str(e)}"
#         }), 500

# @app.route("/list-jobs", methods=['GET'])
# @cross_origin()
# def list_training_jobs():
#     """
#     List recent training jobs
#     """
#     try:
#         response = batch_client.list_jobs(
#             jobQueue=BATCH_JOB_QUEUE,
#             maxResults=10
#         )
        
#         jobs = []
#         for job in response['jobList']:
#             jobs.append({
#                 'job_id': job['jobId'],
#                 'job_name': job['jobName'],
#                 'status': job['jobStatus'],
#                 'created_at': job['createdAt']
#             })
        
#         return jsonify({
#             "status": "success",
#             "jobs": jobs
#         })
        
#     except Exception as e:
#         return jsonify({
#             "status": "error",
#             "message": f"Failed to list jobs: {str(e)}"
#         }), 500

# @app.route("/predict", methods=['POST'])
# @cross_origin()
# def predictionRoute():
#     """
#     Make prediction using the trained model
#     """
#     try:
#         image = request.json['image']
#         decodeImage(image, clApp.filename)
#         result = clApp.classifier.predict()
#         return jsonify(result)
#     except Exception as e:
#         return jsonify({
#             "status": "error",
#             "message": f"Prediction failed: {str(e)}"
#         }), 500

# @app.route("/download-model/<job_id>", methods=['GET'])
# @cross_origin()
# def download_model(job_id):
#     """
#     Download trained model from S3
#     """
#     try:
#         model_key = f'model/model_{job_id}.h5'
        
#         # Generate presigned URL for model download
#         url = s3_client.generate_presigned_url(
#             'get_object',
#             Params={'Bucket': S3_BUCKET, 'Key': model_key},
#             ExpiresIn=3600  # 1 hour
#         )
        
#         return jsonify({
#             "status": "success",
#             "download_url": url,
#             "expires_in": "1 hour"
#         })
        
#     except Exception as e:
#         return jsonify({
#             "status": "error",
#             "message": f"Failed to generate download URL: {str(e)}"
#         }), 500

# if __name__ == "__main__":
#     clApp = ClientApp()
    
#     # Check if running in AWS environment
#     if os.getenv('AWS_EXECUTION_ENV'):
#         app.run(host='0.0.0.0', port=8080, debug=False)
#     else:
#         app.run(host='0.0.0.0', port=8080, debug=True)

from flask import Flask, request, jsonify, render_template
import os
import boto3
import json
import time
import logging
from flask_cors import CORS, cross_origin
from cnnClassifier.utils.common import decodeImage
from cnnClassifier.pipeline.prediction import PredictionPipeline

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize flask
os.putenv('LANG', 'en_US.UTF-8')
os.putenv('LC_ALL', 'en_US.UTF-8')

app = Flask(__name__)
CORS(app)

# AWS Configuration
AWS_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
S3_BUCKET = os.getenv('S3_BUCKET', '')
BATCH_JOB_QUEUE = os.getenv('BATCH_JOB_QUEUE', '')
BATCH_JOB_DEFINITION = os.getenv('BATCH_JOB_DEFINITION', 'kidney-disease-training-job')

# Initialize AWS clients with error handling
try:
    batch_client = boto3.client('batch', region_name=AWS_REGION)
    s3_client = boto3.client('s3', region_name=AWS_REGION)
    
    # Test AWS connectivity
    batch_client.describe_compute_environments(maxResults=1)
    logger.info("✅ AWS Batch client initialized successfully")
    
except Exception as e:
    logger.error(f"❌ Failed to initialize AWS clients: {e}")
    batch_client = None
    s3_client = None

class ClientApp:
    def __init__(self):
        self.filename = "inputImage.jpg"
        try:
            self.classifier = PredictionPipeline(self.filename)
            logger.info("✅ Prediction pipeline initialized")
        except Exception as e:
            logger.error(f"❌ Failed to initialize prediction pipeline: {e}")
            self.classifier = None

@app.route("/", methods=['GET'])
@cross_origin()
def home():
    return render_template('index.html')

@app.route("/health", methods=['GET'])
@cross_origin()
def health_check():
    """Enhanced health check"""
    health_status = {
        "status": "healthy",
        "service": "kidney-disease-classifier",
        "aws_batch": batch_client is not None,
        "s3_bucket": S3_BUCKET,
        "prediction_ready": clApp.classifier is not None
    }
    
    # Test S3 connectivity
    try:
        if s3_client:
            s3_client.head_bucket(Bucket=S3_BUCKET)
            health_status["s3_connectivity"] = True
    except:
        health_status["s3_connectivity"] = False
    
    return jsonify(health_status)

@app.route("/train", methods=['GET', 'POST'])
@cross_origin()
def trainRoute():
    """
    Trigger training using AWS Batch with Spot GPU instances
    """
    if not batch_client:
        return jsonify({
            "status": "error",
            "message": "AWS Batch client not available. Check AWS credentials and configuration."
        }), 500

    if not S3_BUCKET:
        return jsonify({
            "status": "error", 
            "message": "S3_BUCKET environment variable not set"
        }), 500
        
    if not BATCH_JOB_QUEUE:
        return jsonify({
            "status": "error",
            "message": "BATCH_JOB_QUEUE environment variable not set"
        }), 500

    try:
        # Generate unique job name (AWS Batch has strict naming requirements)
        timestamp = int(time.time())
        job_name = f'kidney-disease-training-{timestamp}'
        
        # Submit job to AWS Batch
        response = batch_client.submit_job(
            jobName=job_name,
            jobQueue=BATCH_JOB_QUEUE,
            jobDefinition=BATCH_JOB_DEFINITION,
            parameters={
                'inputDataPath': f's3://{S3_BUCKET}/data/',
                'outputModelPath': f's3://{S3_BUCKET}/model/',
                'configPath': f's3://{S3_BUCKET}/config/'
            },
            timeout={
                'attemptDurationSeconds': 7200  # 2 hours timeout
            }
        )
        
        job_id = response['jobId']
        
        logger.info(f"Training job submitted: {job_id}")
        
        return jsonify({
            "status": "success",
            "message": f"Training job submitted successfully",
            "job_id": job_id,
            "job_name": job_name,
            "queue": BATCH_JOB_QUEUE,
            "note": "Training is running on AWS Batch with Spot GPU instances. Use /train-status/<job_id> to check progress."
        })
        
    except Exception as e:
        logger.error(f"Training job submission failed: {e}")
        return jsonify({
            "status": "error",
            "message": f"Failed to submit training job: {str(e)}"
        }), 500

@app.route("/train-status/<job_id>", methods=['GET'])
@cross_origin()
def get_training_status(job_id):
    """
    Get training job status from AWS Batch
    """
    if not batch_client:
        return jsonify({
            "status": "error",
            "message": "AWS Batch client not available"
        }), 500

    try:
        response = batch_client.describe_jobs(jobs=[job_id])
        
        if not response['jobs']:
            return jsonify({
                "status": "error",
                "message": "Job not found"
            }), 404
        
        job = response['jobs'][0]
        job_status = job['jobStatus']
        
        result = {
            "job_id": job_id,
            "status": job_status,
            "job_name": job['jobName'],
            "created_at": job['createdAt'],
            "job_queue": job['jobQueue']
        }
        
        if 'startedAt' in job:
            result['started_at'] = job['startedAt']
        
        if 'stoppedAt' in job:
            result['stopped_at'] = job['stoppedAt']
            
        if 'statusReason' in job:
            result['status_reason'] = job['statusReason']

        # Add attempt information for debugging
        if 'attempts' in job and job['attempts']:
            attempt = job['attempts'][0]
            if 'exitCode' in attempt:
                result['exit_code'] = attempt['exitCode']
            if 'reason' in attempt:
                result['exit_reason'] = attempt['reason']
            
        # If job is completed, check for results in S3
        if job_status == 'SUCCEEDED' and s3_client:
            try:
                # Check if model exists in S3
                s3_client.head_object(Bucket=S3_BUCKET, Key='model/model.h5')
                result['model_available'] = True
                result['model_s3_path'] = f's3://{S3_BUCKET}/model/model.h5'
            except:
                try:
                    # Check job-specific model
                    s3_client.head_object(Bucket=S3_BUCKET, Key=f'models/model_{job_id}.h5')
                    result['model_available'] = True
                    result['model_s3_path'] = f's3://{S3_BUCKET}/models/model_{job_id}.h5'
                except:
                    result['model_available'] = False
                
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Failed to get job status: {e}")
        return jsonify({
            "status": "error",
            "message": f"Failed to get job status: {str(e)}"
        }), 500

@app.route("/list-jobs", methods=['GET'])
@cross_origin()
def list_training_jobs():
    """
    List recent training jobs
    """
    if not batch_client:
        return jsonify({
            "status": "error",
            "message": "AWS Batch client not available"
        }), 500

    try:
        # Get running jobs
        running_response = batch_client.list_jobs(
            jobQueue=BATCH_JOB_QUEUE,
            jobStatus='RUNNING',
            maxResults=5
        )
        
        # Get recent completed jobs
        completed_response = batch_client.list_jobs(
            jobQueue=BATCH_JOB_QUEUE,
            jobStatus='SUCCEEDED',
            maxResults=5
        )
        
        # Get failed jobs
        failed_response = batch_client.list_jobs(
            jobQueue=BATCH_JOB_QUEUE,
            jobStatus='FAILED',
            maxResults=5
        )
        
        all_jobs = []
        
        for job_list, status in [(running_response['jobList'], 'RUNNING'),
                                (completed_response['jobList'], 'SUCCEEDED'),
                                (failed_response['jobList'], 'FAILED')]:
            for job in job_list:
                all_jobs.append({
                    'job_id': job['jobId'],
                    'job_name': job['jobName'],
                    'status': job['jobStatus'],
                    'created_at': job['createdAt']
                })
        
        # Sort by creation time (most recent first)
        all_jobs.sort(key=lambda x: x['created_at'], reverse=True)
        
        return jsonify({
            "status": "success",
            "jobs": all_jobs[:10]  # Return top 10 most recent
        })
        
    except Exception as e:
        logger.error(f"Failed to list jobs: {e}")
        return jsonify({
            "status": "error",
            "message": f"Failed to list jobs: {str(e)}"
        }), 500

@app.route("/predict", methods=['POST'])
@cross_origin()
def predictionRoute():
    """
    Make prediction using the trained model
    """
    if not clApp.classifier:
        return jsonify({
            "status": "error",
            "message": "Prediction pipeline not available. Model may not be loaded."
        }), 500

    try:
        if not request.json or 'image' not in request.json:
            return jsonify({
                "status": "error",
                "message": "No image data provided in request"
            }), 400
            
        image = request.json['image']
        decodeImage(image, clApp.filename)
        result = clApp.classifier.predict()
        
        return jsonify({
            "status": "success",
            "prediction": result
        })
        
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        return jsonify({
            "status": "error",
            "message": f"Prediction failed: {str(e)}"
        }), 500

@app.route("/download-model/<job_id>", methods=['GET'])
@cross_origin()
def download_model(job_id):
    """
    Download trained model from S3
    """
    if not s3_client:
        return jsonify({
            "status": "error",
            "message": "S3 client not available"
        }), 500

    try:
        model_key = f'models/model_{job_id}.h5'
        
        # Check if model exists
        try:
            s3_client.head_object(Bucket=S3_BUCKET, Key=model_key)
        except:
            return jsonify({
                "status": "error",
                "message": "Model not found in S3"
            }), 404
        
        # Generate presigned URL for model download
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': model_key},
            ExpiresIn=3600  # 1 hour
        )
        
        return jsonify({
            "status": "success",
            "download_url": url,
            "model_key": model_key,
            "expires_in": "1 hour"
        })
        
    except Exception as e:
        logger.error(f"Failed to generate download URL: {e}")
        return jsonify({
            "status": "error",
            "message": f"Failed to generate download URL: {str(e)}"
        }), 500
        
clApp = ClientApp() 


if __name__ == "__main__":
    clApp = ClientApp()
    
    # Print configuration info
    logger.info(f"S3 Bucket: {S3_BUCKET}")
    logger.info(f"Batch Job Queue: {BATCH_JOB_QUEUE}")
    logger.info(f"AWS Region: {AWS_REGION}")
    
    # Check if running in AWS environment
    if os.getenv('AWS_EXECUTION_ENV'):
        logger.info("Running in AWS environment")
        app.run(host='0.0.0.0', port=8080, debug=False)
    else:
        logger.info("Running in local environment")
        app.run(host='0.0.0.0', port=8080, debug=True)