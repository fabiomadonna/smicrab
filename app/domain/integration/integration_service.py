import json
import os
from typing import Type, TypeVar
from pydantic import BaseModel
from pathlib import Path

from app.utils import Logger
from app.utils.utils import get_base_analysis_path

T = TypeVar("T", bound=BaseModel)


class IntegrationService:
    def __init__(self):
        self.analysis_base_path = get_base_analysis_path()
        self._ensure_directory_exists(self.analysis_base_path)

    def _ensure_directory_exists(self, path: str) -> None:
        """Helper method to ensure directory exists"""
        try:
            # Create directory and parents if they don't exist
            os.makedirs(path, exist_ok=True)

            # Verify it's a directory
            if not os.path.isdir(path):
                raise OSError(f"Path is not a directory: {path}")

        except OSError as e:
            Logger.error(
                f"Failed to create directory {path}: {e}",
                context={"task": "ensure_directory_exists", "message": str(e)},
            )
            raise

    def get_analysis_path(self, analysis_id: str, module_name: str) -> str:
        """Get analysis directory path for specific module."""
        output_path = os.path.join(self.analysis_base_path, analysis_id, module_name)
        self._ensure_directory_exists(output_path)
        return output_path

    def _save_result_to_file(
        self,
        response_data: BaseModel,
        file_path: str,
        indent: int = 2,
    ) -> None:
        """
        Generic method to save BaseModel (DTO) to JSON file.
        Following R integration protocol: save R result DTOs to file.
        """
        self._ensure_directory_exists(file_path)
        with open(file_path, "w") as f:
            json.dump(response_data.model_dump(), f, indent=indent)

    def _read_data_from_file(self, file_path: str, response_model: Type[T]) -> T:
        """
        Generic method to load BaseModel from JSON file.
        Following R integration protocol: read previous step results.
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Previous step file not found: {file_path}")

        with open(file_path, "r") as f:
            data = json.load(f)
        return response_model(**data)

    def _get_previous_step_path(
        self, analysis_id: str, module_name: str, step_name: str
    ) -> str:
        """
        Get the path to a previous step's output file.
        Following R integration protocol: read from previous module steps.
        """
        analysis_path = self.get_analysis_path(analysis_id, module_name)
        return os.path.join(analysis_path, f"{step_name}.json")

    def _get_step_output_path(
        self, analysis_id: str, module_name: str, step_name: str
    ) -> str:
        """
        Get the output path for current step.
        Following R integration protocol: standardized output paths.
        """
        analysis_path = self.get_analysis_path(analysis_id, module_name)
        return os.path.join(analysis_path, f"{step_name}.json")
