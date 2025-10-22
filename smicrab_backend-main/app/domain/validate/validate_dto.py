from datetime import datetime
from uuid import UUID
from typing import List, Optional, Dict, Any
from sqlalchemy.dialects.postgresql import JSONB

from pydantic import BaseModel, Field

from app.utils.enums import ValidateStep, StepProgressStatus, ModelType


class ValidateModuleSchema(BaseModel):
    id: UUID
    analysis_id: UUID
    current_step: ValidateStep
    step_progress: StepProgressStatus
    completed: bool
    completed_at: Optional[datetime]
    total_steps: int
    data_reference: Optional[Dict[str, Any]] = Field(sa_type=JSONB)
    created_at: datetime
    updated_at: datetime

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
            ValidateStep: lambda step: step.value,
            StepProgressStatus: lambda status: status.value,
        }
        from_attributes = True


# DTOs for validate module outputs

class ValidateModuleFile(BaseModel):
    """File information for validate module outputs."""
    name: str = Field(..., description="File name identifier")
    path_dynamic: Optional[str] = Field(None, description="Dynamic HTML file path")
    path_static: Optional[str] = Field(None, description="Static PNG file path")
    function: Optional[str] = Field(None, description="R function used to generate the file")
    description: Optional[str] = Field(None, description="File description")

    class Config:
        from_attributes = True


class ResidualSummaryStatistics(BaseModel):
    """Residual summary statistics output."""
    description: str = Field(..., description="Description of residual summary statistics")
    files: List[ValidateModuleFile] = Field(..., description="List of residual statistics files")

    class Config:
        from_attributes = True


class AutocorrelationTests(BaseModel):
    """Autocorrelation tests output."""
    description: str = Field(..., description="Description of autocorrelation tests")
    files: List[ValidateModuleFile] = Field(..., description="List of autocorrelation test files")

    class Config:
        from_attributes = True


class NormalityTests(BaseModel):
    """Normality tests output."""
    description: str = Field(..., description="Description of normality tests")
    files: List[ValidateModuleFile] = Field(..., description="List of normality test files")

    class Config:
        from_attributes = True


class BootstrapComparison(BaseModel):
    """Bootstrap comparison output."""
    description: str = Field(..., description="Description of bootstrap comparison")
    files: List[ValidateModuleFile] = Field(..., description="List of bootstrap comparison files")

    class Config:
        from_attributes = True


class ParameterDistribution(BaseModel):
    """Parameter distribution output."""
    description: str = Field(..., description="Description of parameter distribution")
    files: List[ValidateModuleFile] = Field(..., description="List of parameter distribution files")

    class Config:
        from_attributes = True


class BootstrapValidation(BaseModel):
    """Bootstrap validation output."""
    description: str = Field(..., description="Description of bootstrap validation results")
    bootstrap_comparison: BootstrapComparison = Field(..., description="Bootstrap comparison results")
    parameter_distribution: ParameterDistribution = Field(..., description="Parameter distribution results")

    class Config:
        from_attributes = True


class ValidateModuleOutputs(BaseModel):
    """Complete validate module outputs structure."""
    residual_summary_statistics: ResidualSummaryStatistics = Field(..., description="Residual summary statistics plots")
    autocorrelation_tests: AutocorrelationTests = Field(..., description="Ljung-Box autocorrelation test results")
    normality_tests: NormalityTests = Field(..., description="Jarque-Bera normality test results")
    bootstrap_validation: BootstrapValidation = Field(..., description="Bootstrap validation results for H-SDPD models")

    class Config:
        from_attributes = True


class ModelSpecificAvailability(BaseModel):
    """Model specific availability for validation features."""
    residual_summary_statistics: bool = Field(..., description="Whether residual summary statistics are available")
    autocorrelation_tests: bool = Field(..., description="Whether autocorrelation tests are available")
    normality_tests: bool = Field(..., description="Whether normality tests are available")
    bootstrap_validation: bool = Field(..., description="Whether bootstrap validation is available")

    class Config:
        from_attributes = True


class ModelSpecificAvailabilitySet(BaseModel):
    """Model-specific availability set for validation features."""
    Model1_Simple: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=False,
        autocorrelation_tests=False,
        normality_tests=False,
        bootstrap_validation=False
    ))
    Model2_Autoregressive: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=True,
        autocorrelation_tests=True,
        normality_tests=True,
        bootstrap_validation=False
    ))
    Model3_MB_User: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=True,
        autocorrelation_tests=True,
        normality_tests=True,
        bootstrap_validation=False
    ))
    Model4_UHI: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=True,
        autocorrelation_tests=True,
        normality_tests=True,
        bootstrap_validation=True
    ))
    Model5_RAB: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=True,
        autocorrelation_tests=True,
        normality_tests=True,
        bootstrap_validation=True
    ))
    Model6_HSDPD_user: ModelSpecificAvailability = Field(default_factory=lambda: ModelSpecificAvailability(
        residual_summary_statistics=True,
        autocorrelation_tests=True,
        normality_tests=True,
        bootstrap_validation=True
    ))

    class Config:
        from_attributes = True


class GetValidateOutputsResponse(BaseModel):
    """Response schema for getting validate module outputs."""
    validate_module_outputs: ValidateModuleOutputs = Field(..., description="Complete validate module outputs")
    model_specific_availability: ModelSpecificAvailabilitySet = Field(
        ..., description="Model-specific availability of validation features"
    )

    class Config:
        from_attributes = True