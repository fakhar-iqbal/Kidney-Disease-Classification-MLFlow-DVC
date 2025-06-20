from cnnClassifier import logger
from cnnClassifier.pipeline.stage04_model_evaluation import EvaluateModelPipeline
from cnnClassifier.pipeline.stage02_prepare_base_model import PrepareBaseModelPipeline
from cnnClassifier.pipeline.stage01_data_ingestion import DataIngestionTrainingPipeline
from cnnClassifier.pipeline.stage03_training import TrainingPipeline

STAGE_NAME = "Data Ingestion Stage"

try:
    logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
    data_ingestion = DataIngestionTrainingPipeline()
    data_ingestion.main()
    logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
except Exception as e:
    logger.exception(e)
    raise e


STAGE_NAME = "Prepare Base Model Stage"

try:
    logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
    prepare_base_model = PrepareBaseModelPipeline()
    prepare_base_model.main()
    logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
except Exception as e:
    logger.exception(e)
    raise e

STAGE_NAME = "Training Model Stage"


try:
    logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
    training_model = TrainingPipeline()
    training_model.main()
    logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
except Exception as e:
    raise e


STAGE_NAME = "Evaluate Model Stage"


try:
    logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
    eval_model = EvaluateModelPipeline()
<<<<<<< HEAD
    eval_model.main()
=======
    eval.main()
>>>>>>> 5adff314d02f66028c6e638381928b3ec4252372
    logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx=============x")
except Exception as e:
    raise e