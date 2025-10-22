from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.utils.enums import ModelType, AnalysisVariable


class EstimateModuleFile(BaseModel):
    """File information for estimate module outputs."""
    name: str = Field(..., description="File name identifier")
    path_dynamic: Optional[str] = Field(None, description="Dynamic HTML file path")
    path_static: Optional[str] = Field(None, description="Static PNG/CSV file path")
    function: Optional[str] = Field(None, description="R function used to generate this output")
    description: Optional[str] = Field(None, description="File description")

    class Config:
        from_attributes = True


class CoefficientTables(BaseModel):
    """Coefficient tables output."""
    description: str = Field(..., description="Description of coefficient tables")
    files: List[EstimateModuleFile] = Field(..., description="List of coefficient table files")

    class Config:
        from_attributes = True


class CoefficientPlots(BaseModel):
    """Coefficient plots output."""
    description: str = Field(..., description="Description of coefficient plots")
    trend_plots: List[EstimateModuleFile] = Field(..., description="Trend coefficient plots")
    covariate_plots: List[EstimateModuleFile] = Field(..., description="Covariate coefficient plots")
    spatial_autocorrelation_plots: List[EstimateModuleFile] = Field(..., description="Spatial autocorrelation plots")
    fixed_effects_plots: List[EstimateModuleFile] = Field(..., description="Fixed effects plots")

    class Config:
        from_attributes = True


class TimeSeriesPlots(BaseModel):
    """Time series plots output."""
    description: str = Field(..., description="Description of time series plots")
    files: List[EstimateModuleFile] = Field(..., description="List of time series plot files")

    class Config:
        from_attributes = True


class CsvDownloads(BaseModel):
    """CSV downloads output."""
    description: str = Field(..., description="Description of CSV downloads")
    files: List[EstimateModuleFile] = Field(..., description="List of CSV files")

    class Config:
        from_attributes = True


class EstimateModuleOutputs(BaseModel):
    """Complete estimate module outputs structure."""
    coefficient_tables: CoefficientTables = Field(..., description="Interactive tables with estimated parameters")
    coefficient_plots: CoefficientPlots = Field(..., description="Spatial plots of estimated coefficients")
    time_series_plots: TimeSeriesPlots = Field(..., description="Fitted and residual time series plots")
    csv_downloads: CsvDownloads = Field(..., description="Downloadable CSV files with estimation results")

    class Config:
        from_attributes = True


class ModelAvailability(BaseModel):
    """Availability of outputs for a specific model."""
    coefficient_tables: bool = Field(..., description="Whether coefficient tables are available")
    coefficient_plots: bool = Field(..., description="Whether coefficient plots are available")
    time_series_plots: bool = Field(..., description="Whether time series plots are available")
    csv_downloads: bool = Field(..., description="Whether CSV downloads are available")

    class Config:
        from_attributes = True


class ModelSpecificAvailability(BaseModel):
    """Model-specific availability of outputs."""
    Model1_Simple: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=False,
        coefficient_plots=False,
        time_series_plots=False,
        csv_downloads=False
    ))
    Model2_Autoregressive: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=True,
        coefficient_plots=True,
        time_series_plots=True,
        csv_downloads=True
    ))
    Model3_MB_User: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=True,
        coefficient_plots=True,
        time_series_plots=True,
        csv_downloads=True
    ))
    Model4_UHI: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=True,
        coefficient_plots=True,
        time_series_plots=True,
        csv_downloads=True
    ))
    Model5_RAB: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=True,
        coefficient_plots=True,
        time_series_plots=True,
        csv_downloads=True
    ))
    Model6_HSDPD_user: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        coefficient_tables=True,
        coefficient_plots=True,
        time_series_plots=True,
        csv_downloads=True
    ))

    class Config:
        from_attributes = True


class GetEstimateOutputsResponse(BaseModel):
    """Response schema for getting estimate module outputs."""
    estimate_module_outputs: EstimateModuleOutputs = Field(..., description="Complete estimate module outputs")
    model_specific_availability: ModelSpecificAvailability = Field(
        default_factory=ModelSpecificAvailability,
        description="Availability of estimate module features for different models"
    )

    class Config:
        from_attributes = True