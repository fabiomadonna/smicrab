import os
import json
from typing import Dict, Any
from app.domain.integration.integration_service import IntegrationService
from app.utils import get_parameters_file


class AnalysisIntegrationService(IntegrationService):
    def __init__(self):
        super().__init__()

    def save_analysis_parameters(
        self,
        analysis_id: str,
        parameters: Dict[str, Any],
    ) -> None:
        """
        Save analysis parameters to a JSON file in the analysis parameters directory.

        Args:
            analysis_id (str): Unique identifier for the analysis
            parameters (Dict[str, Any]): Parameters to save
        """
        # Ensure the parameters directory exists

        # Save parameters to a JSON file
        parameters_file = get_parameters_file(analysis_id)

        print("parameters_file: ", parameters_file)
        with open(parameters_file, "w") as f:
            json.dump(parameters, f, indent=2)
