from datetime import datetime
from uuid import UUID
from typing import List, Optional, Dict, Any
from sqlalchemy.dialects.postgresql import JSONB

from pydantic import BaseModel, Field

from app.domain.dataset.dataset_dto import Raster, Covariate
from app.utils.enums import LoadStep, StepProgressStatus, ModelType


class LoadModuleSchema(BaseModel):
    id: UUID
    analysis_id: UUID
    current_step: LoadStep
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
            LoadStep: lambda step: step.value,
            StepProgressStatus: lambda status: status.value,
        }
        from_attributes = True


# class BaseLoaModuleConfig(BaseModel):
#     r_path: str = Field("", description="Output path of R execution")
#     metadata: Dict[str, Any] = Field(default_factory=dict, description="R Metadata")


# ----------------------- Start LoadModule DTOs ------------------
class StartLoadModuleRequest(BaseModel):
    """Request schema for starting load module."""

    analysis_id: str = Field(..., description="ID of the analysis")

    class Config:
        from_attributes = True


class StartLoadModuleResponse(LoadModuleSchema):
    """Response schema for starting load module."""

    start_date: datetime
    end_date: datetime
    available_rasters: List[Raster]

    class Config:
        from_attributes = True


# ----------------------- Model Configuration DTOs ------------------
class VariableConfiguration(BaseModel):
    id: str = Field(..., description="Endogenous Variable identifier")
    x_leg: Optional[int] = Field(None, description="Lag of the variable (optional)")


class ModelConfiguration(BaseModel):
    analysis_id: str = Field(..., description="Analysis ID")
    model_type: ModelType
    endogenous_variable: Raster
    covariate_variables: List[Covariate]
    max_lag: int
    include_trend: bool

    class Config:
        json_encoders = {
            Raster: lambda raster: raster.model_dump(),
            Covariate: lambda covariate: covariate.model_dump(),
            ModelType: lambda model_type: model_type.value,
        }
        from_attributes = True


class ModelConfigurationRequest(BaseModel):
    """Request for configuring the SMICRAB model."""

    analysis_id: str = Field(..., description="Analysis ID")
    model_type: ModelType = Field(
        ..., description="Model type: Model1_UHI, Model2_RAB, Model3_Parse, Model4_user"
    )
    endogenous_variable: VariableConfiguration
    covariate_variables: List[VariableConfiguration]
    include_trend: bool = Field(True, description="Include trend in model")


# ----------------------- Build Dataframe DTOs ------------------
class BuildDataframeOption(BaseModel):
    px_core: int = Field(1, description="PX core Option")
    px_neighbors: int = Field(3, description="PX neighbors Option")
    t_frequency: int = Field(12, description="Time frequency Option")
    na_rm: bool = Field(True, description="NA Remove Option")
    groups: int = Field(1, description="Group Option")
    na_covs: str = Field("pairwise.complete.obs", description="NA Covariate Option")

    class Config:
        from_attributes = True


class BuildDataframeRequest(BaseModel):
    """Request schema for building dataframes."""

    analysis_id: str = Field("default_analysis", description="Analysis ID")
    px_core: int = Field(1, description="PX core Option")
    px_neighbors: int = Field(3, description="PX neighbors Option")
    t_frequency: int = Field(12, description="Time frequency Option")
    na_rm: bool = Field(True, description="NA Remove Option")
    groups: int = Field(1, description="Group Option")
    na_covs: str = Field("pairwise.complete.obs", description="NA Covariate Option")

    class Config:
        from_attributes = True


class BuildDataframeResponse(BaseModel):
    """Response schema for building dataframes."""

    status: str
    message: str
    df_data_path: str = Field(..., description="Path to the built df.data object")
    global_series_path: str = Field(..., description="Path to the global.series object")
    df_gruppi_path: str = Field(..., description="Path to the df.gruppi object")
    metadata: Dict[str, Any] = Field(default_factory=dict)

    class Config:
        from_attributes = True


class VariableSelectionRequest(BaseModel):
    """Request schema for selecting variables to download."""

    analysis_id: str = Field(..., description="Analysis ID")
    variable_selections: List[str] = Field(
        ...,
        description="array for selected variable IDs",
    )

    class Config:
        from_attributes = True


class VariableSelectionResponse(BaseModel):
    """Response schema after variable selection."""

    status: str
    message: str
    selected_variables: List[str] = Field(
        ..., description="Names of selected variables"
    )
    dataframes_path: str = Field(..., description="Path to dataframes list object")
    available_downloads: List[str] = Field(
        ..., description="List of CSV files available for download"
    )

    class Config:
        from_attributes = True


# ----------------------- Complete Load Module DTOs ------------------
class CompleteLoadModuleRequest(BaseModel):
    """Request schema for completing load module."""

    analysis_id: str = Field(..., description="Analysis ID")

    class Config:
        from_attributes = True


class LoadModuleStatusResponse(BaseModel):
    """Response DTO for load module status."""

    id: UUID
    analysis_id: UUID
    current_step: LoadStep
    step_progress: StepProgressStatus
    completed: bool = Field(default=False)
    completed_at: Optional[datetime] = None
    data_reference: Optional[Dict[str, Any]] = Field(sa_type=JSONB)

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat(),
            UUID: lambda uuid: str(uuid),
            LoadStep: lambda step: step.value,
            StepProgressStatus: lambda status: status.value,
        }
        from_attributes = True
