from typing import Optional, List, Dict, Any
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field
from app.Models.analysis import AnalyzeStatus
from app.utils.enums import ModuleName, ModelType, AnalysisVariable, SummaryStat


class AnalysisSchema(BaseModel):
    id: UUID
    user_id: UUID
    status: AnalyzeStatus
    current_module: ModuleName
    model_config_data: Optional[Dict[str, Any]] = None
    model_type: Optional[ModelType] = None
    coordinates: Optional[Dict[str, Any]] = None
    is_dynamic_output: Optional[bool] = False
    analysis_date: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
            AnalyzeStatus: lambda status: status.value,
            ModuleName: lambda module: module.value,
            ModelType: lambda model_type: model_type.value,
        }
        from_attributes = True


class CreateAnalysisRequest(BaseModel):
    """Request schema for creating a new analysis session."""

    user_id: str = Field(..., description="User identifier")

    class Config:
        from_attributes = True


class VectorOptionsDTO(BaseModel):
    """DTO for vector options in analysis parameters."""
    groups: int = Field(1, description="Number of groups")
    px_core: int = Field(1, description="Core pixel count")
    px_neighbors: int = Field(3, description="Neighbor pixel count")
    t_frequency: int = Field(12, description="Time frequency")
    na_rm: bool = Field(True, description="Remove NA values")
    NAcovs: str = Field("pairwise.complete.obs", description="NA covariate handling method")

    class Config:
        from_attributes = True


class SaveAnalysisParametersRequest(BaseModel):
    """Request schema for saving analysis parameters."""

    analysis_id: str = Field(..., description="Analysis identifier")
    model_type: ModelType
    bool_update: bool = Field(False, description="Update flag")
    bool_trend: bool = Field(False, description="Trend flag")
    summary_stat: SummaryStat = Field(..., description="Summary statistic method")
    user_longitude_choice: float = Field(..., description="User selected longitude")
    user_latitude_choice: float = Field(..., description="User selected latitude")
    user_coeff_choice: float = Field(1.0, description="User coefficient choice")
    bool_dynamic: bool = Field(False, description="Dynamic output flag")
    endogenous_variable: AnalysisVariable = Field(..., description="Endogenous variable")
    covariate_variables: List[AnalysisVariable] = Field(default_factory=list, description="Covariate variables")
    covariate_legs: List[int] = Field(default_factory=list, description="Lag values for covariate variables")
    user_date_choice: Optional[str] = Field(None, description="User selected date")
    vec_options: Optional[VectorOptionsDTO] = Field(None, description="Vector options")

    class Config:
        json_encoders = {
            ModelType: lambda modelType: modelType.value,
            AnalysisVariable: lambda var: var.value,
            SummaryStat: lambda stat: stat.value,
        }
        from_attributes = True


class RunAnalysisRequest(BaseModel):
    """Request schema for running analysis."""

    analysis_id: str = Field(..., description="Analysis ID")

    class Config:
        from_attributes = True


class RunAnalysisResponse(BaseModel):
    """Response schema for running analysis."""

    analysis_id: str = Field(..., description="Analysis ID")
    status: AnalyzeStatus = Field(..., description="Current analysis status")
    execution_started: bool = Field(..., description="Whether execution has started")
    message: str = Field(..., description="Status message")

    class Config:
        from_attributes = True


class AnalysisWebhookRequest(BaseModel):
    """Request schema for analysis completion webhook."""

    analysis_id: str = Field(..., description="Analysis ID")
    status: str = Field(
        ..., description="Completion status: 'done', 'error', 'timeout', or 'module_completed'"
    )
    error_message: Optional[str] = Field(
        None, description="Error message if status is error"
    )
    current_module: Optional[str] = Field(
        None, description="Current module name for module_completed status"
    )
    next_module: Optional[str] = Field(
        None, description="Next module name for module_completed status"
    )

    class Config:
        from_attributes = True


class AnalysisWebhookResponse(BaseModel):
    """Response schema for analysis completion webhook."""

    success: bool = Field(..., description="Whether webhook was processed successfully")
    message: str = Field(..., description="Status message")
    analysis_id: str = Field(..., description="Analysis ID")
    updated_status: AnalyzeStatus = Field(..., description="Updated analysis status")

    class Config:
        json_encoders = {
            AnalyzeStatus: lambda status: status.value,
        }
        from_attributes = True


class UserAnalysesResponse(BaseModel):
    """Response schema for retrieving user's analyses."""

    analyses: List[AnalysisSchema]

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
        }
