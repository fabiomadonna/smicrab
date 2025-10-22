from typing import List, Optional, Dict
from pydantic import BaseModel, Field
from app.utils.enums import AnalysisVariable, ModelType


class DescribeModuleFile(BaseModel):
    """Individual file output structure."""
    name: str = Field(..., description="File name identifier")
    variable: Optional[AnalysisVariable] = Field(None, description="Variable name")
    path_dynamic: Optional[str] = Field(None, description="Path to dynamic HTML file")
    path_static: Optional[str] = Field(None, description="Path to static PNG file")
    function: Optional[str] = Field(None, description="R function used to generate this output")
    description: Optional[str] = Field(None, description="File description")

    class Config:
        from_attributes = True


class DescribeModuleDataExports(BaseModel):
    """Data export paths structure."""
    endogenous_variable_csv: str = Field(..., description="Path to endogenous variable CSV file")

    class Config:
        from_attributes = True


class DescribeModulePlotGroup(BaseModel):
    """Plot group structure with description and files."""
    description: str = Field(..., description="Description of the plot group")
    files: List[DescribeModuleFile] = Field(..., description="List of output files")

    class Config:
        from_attributes = True


class DescribeModuleStatistics(BaseModel):
    """Statistics data exports structure."""
    variable_summary_statistics: str = Field(..., description="Path to variable summary statistics JSON file")
    pixel_time_series_data: str = Field(..., description="Path to pixel time series data JSON file")

    class Config:
        from_attributes = True


class DescribeModuleOutputs(BaseModel):
    """Complete describe module outputs structure."""
    data_exports: DescribeModuleDataExports = Field(..., description="Data export paths")
    spatial_distribution_plots: DescribeModulePlotGroup = Field(..., description="Spatial distribution plots")
    temporal_distribution_plots: DescribeModulePlotGroup = Field(..., description="Temporal distribution plots (STL decomposition)")
    summary_statistics_plots: DescribeModulePlotGroup = Field(..., description="Summary statistics plots")
    statistics_data: DescribeModuleStatistics = Field(..., description="Statistics data files")

    class Config:
        from_attributes = True


class ModelAvailability(BaseModel):
    """Availability of describe module features for a specific model."""
    data_exports: bool = Field(default=False, description="Availability of data exports")
    spatial_distribution_plots: bool = Field(default=False, description="Availability of spatial distribution plots")
    temporal_distribution_plots: bool = Field(default=False, description="Availability of temporal distribution plots")
    summary_statistics_plots: bool = Field(default=False, description="Availability of summary statistics plots")
    statistics_data: bool = Field(default=False, description="Availability of statistics data files")


class ModelSpecificAvailability(BaseModel):
    """Availability of describe module features across different models."""
    Model1_Simple: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))
    Model2_Autoregressive: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))
    Model3_MB_User: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))
    Model4_UHI: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))
    Model5_RAB: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))
    Model6_HSDPD_user: ModelAvailability = Field(default_factory=lambda: ModelAvailability(
        data_exports=True,
        spatial_distribution_plots=True,
        temporal_distribution_plots=True,
        summary_statistics_plots=True,
        statistics_data=True
    ))


class GetDescribeModuleOutputsResponse(BaseModel):
    """Response schema for getting describe module outputs."""
    describe_module_outputs: DescribeModuleOutputs = Field(..., description="Complete describe module outputs")
    model_specific_availability: ModelSpecificAvailability = Field(
        default_factory=ModelSpecificAvailability,
        description="Availability of describe module features for different models"
    )

    class Config:
        from_attributes = True