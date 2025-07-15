import os
from uuid import UUID

from app.utils import ModelType


def get_base_analysis_path() -> str:
    """
    Returns the appropriate base path for analysis directory based on OS.

    Returns:
        Path: Path object pointing to the analysis directory
    """
    if os.name == "nt":  # Windows
        return os.path.join(os.getcwd(), "tmp", "analysis")
    else:  # Linux/Mac
        return "/tmp/analysis"


def get_analysis_path(analysis_id: str) -> str:
    """Get analysis directory path for specific module."""
    base_path = get_base_analysis_path()
    analysis_dir = os.path.join(base_path, analysis_id)
    os.makedirs(analysis_dir, exist_ok=True)
    return analysis_dir


def get_analysis_output_path(analysis_id: UUID, model_type: ModelType) -> str:
    """Get analysis output directory path for specific model type."""
    analysis_path = get_analysis_path(str(analysis_id))
    output_path = os.path.join(analysis_path, model_type.value)
    os.makedirs(output_path, exist_ok=True)
    return output_path


def get_parameters_file(analysis_id: str) -> str:
    # Create analysis directory structure
    base_path = get_base_analysis_path()
    analysis_dir = f"{base_path}/{analysis_id}"
    os.makedirs(analysis_dir, exist_ok=True)

    # Prepare parameters file
    param_path = f"{analysis_dir}/parameters.json"
    return param_path


def get_flag_file(analysis_id: str, model_type: ModelType) -> str:
    base_path = get_base_analysis_path()
    analysis_dir = f"{base_path}/{analysis_id}/{model_type.value}"
    os.makedirs(analysis_dir, exist_ok=True)

    flag_path = f"{analysis_dir}/{analysis_id}.flag"
    return flag_path
