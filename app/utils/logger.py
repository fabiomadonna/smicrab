import logging
from typing import Dict
logger = logging.getLogger(__name__)

class Logger:

    @staticmethod
    def info(message):
        logger.info(message, )

    @staticmethod
    def error(message, context: Dict):
        logger.error(message, context)

    @staticmethod
    def warn(message):
        logger.warning(message)

    @staticmethod
    def debug(message):
        logger.debug(message)

    @staticmethod
    def critical(message):
        logger.critical(message)