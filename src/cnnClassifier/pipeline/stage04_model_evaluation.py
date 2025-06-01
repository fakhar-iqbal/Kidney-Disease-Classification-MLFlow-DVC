from cnnClassifier.config.configuration import ConfigurationManager
from cnnClassifier.components.model_evaluation import Evaluation
from cnnClassifier import logger

STAGE_NAME = "Evaluate Model Stage"

class EvaluateModelPipeline:
    def __init__(self):
        pass
    
    def main(self):
        config = ConfigurationManager()
        eval_config = config.get_evaluation_config()
        evaluation = Evaluation(eval_config)
        evaluation.evaluation()
        # evaluation.log_into_mlflow()
if __name__ == '__main__':
    try:
        logger.info(f">>>>>>>>>>>> stage {STAGE_NAME} started <<<<<<<<<<<<<")
        obj = EvaluateModelPipeline()
        obj.main()
        logger.info(f">>>>>>>>>> stage {STAGE_NAME} completed <<<<<<<<<<\n\nx===========x")
    except Exception as e:
        logger.exception(e)
        raise e
    