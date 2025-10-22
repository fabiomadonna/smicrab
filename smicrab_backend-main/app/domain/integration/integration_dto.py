from uuid import UUID

from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any

from app.domain.dataset.dataset_dto import Raster


class IntegrationResponse(BaseModel):
    status: bool = Field(..., description="Integration execution status")
    message: str = Field(..., description="Integration execution message")
    data_path: str = Field(..., description="Integration Output path")
    metadata: Optional[Dict] = Field(None, description="Integration execution metadata")

    class Config:
        from_attributes = True


# =============================================================================
# LOAD MODULE R INTEGRATION DTOs
# =============================================================================


class RModelConfig(BaseModel):
    """R result DTO for model configuration step."""

    italy_shape_path: str = Field(..., description="Original Italy shapefile path")
    projected_shape_path: str = Field(..., description="Projected shapefile path")
    province_raster_path: str = Field(..., description="Rasterized province data path")
    label_province_mapping: Dict[str, str] = Field(
        ..., description="Province code to name mapping"
    )

    class Config:
        from_attributes = True


class RBuildDataframe(BaseModel):
    """R result DTO for dataframe building step."""

    df_data_path: str = Field(..., description="Path to df.data RDS file")
    global_series_path: str = Field(..., description="Path to global.series RDS file")
    df_gruppi_path: str = Field(..., description="Path to df.gruppi RDS file")
    num_pixels: int = Field(..., description="Number of pixels processed")
    num_groups: int = Field(..., description="Number of groups created")
    time_period: str = Field(..., description="Time period covered")

    class Config:
        from_attributes = True


class RVariableSelection(BaseModel):
    """R result DTO for variable selection and CSV generation."""

    csv_files: List[str] = Field(..., description="List of generated CSV file paths")

    class Config:
        from_attributes = True


# =============================================================================
# DESCRIBE MODULE R INTEGRATION DTOs
# =============================================================================


class RDataSummary(BaseModel):
    """R result DTO for data summary step."""

    summary_statistics_path: str = Field(
        ..., description="Path to summary statistics RDS file"
    )
    summary_table_path: str = Field(..., description="Path to summary table CSV file")
    quality_report_path: str = Field(
        ..., description="Path to data quality HTML report"
    )
    missing_data_analysis_path: str = Field(
        ..., description="Path to missing data analysis"
    )
    total_observations: int = Field(..., description="Total number of observations")
    complete_cases: int = Field(..., description="Number of complete cases")
    variables_analyzed: List[str] = Field(..., description="List of analyzed variables")

    class Config:
        from_attributes = True


class RCorrelationAnalysis(BaseModel):
    """R result DTO for correlation analysis step."""

    correlation_matrix_path: str = Field(
        ..., description="Path to correlation matrix RDS file"
    )
    correlation_plots_path: str = Field(..., description="Path to correlation plots")
    spatial_correlation_path: str = Field(
        ..., description="Path to spatial correlation results"
    )
    temporal_correlation_path: str = Field(
        ..., description="Path to temporal correlation results"
    )
    significance_tests_path: str = Field(
        ..., description="Path to significance test results"
    )

    class Config:
        from_attributes = True


class RDistributionAnalysis(BaseModel):
    """R result DTO for distribution analysis step."""

    distribution_stats_path: str = Field(
        ..., description="Path to distribution statistics RDS file"
    )
    normality_tests_path: str = Field(..., description="Path to normality test results")
    distribution_plots_path: str = Field(..., description="Path to distribution plots")
    outlier_analysis_path: str = Field(
        ..., description="Path to outlier analysis results"
    )

    class Config:
        from_attributes = True


class RTimeSeriesPlots(BaseModel):
    """R result DTO for time series plots step."""

    time_series_plots_path: str = Field(..., description="Path to time series plots")
    decomposition_results_path: str = Field(
        ..., description="Path to decomposition results"
    )
    trend_analysis_path: str = Field(..., description="Path to trend analysis results")
    seasonal_analysis_path: str = Field(
        ..., description="Path to seasonal analysis results"
    )

    class Config:
        from_attributes = True


class RSpatialPlots(BaseModel):
    """R result DTO for spatial plots step."""

    spatial_plots_path: str = Field(..., description="Path to spatial plots")
    spatial_statistics_path: str = Field(
        ..., description="Path to spatial statistics RDS file"
    )
    interpolation_results_path: str = Field(
        ..., description="Path to interpolation results"
    )
    contour_maps_path: str = Field(..., description="Path to contour maps")

    class Config:
        from_attributes = True


class RExportResults(BaseModel):
    """R result DTO for export results step."""

    export_file_path: str = Field(..., description="Path to exported file")
    report_path: str = Field(..., description="Path to generated report")
    archive_path: Optional[str] = Field(None, description="Path to archive file")

    class Config:
        from_attributes = True


# =============================================================================
# ESTIMATE MODULE R INTEGRATION DTOs
# =============================================================================


class RModelSetup(BaseModel):
    """R result DTO for model setup step."""

    model_config_path: str = Field(
        ..., description="Path to model configuration RDS file"
    )
    spatial_weights_path: str = Field(..., description="Path to spatial weights matrix")
    estimation_settings_path: str = Field(
        ..., description="Path to estimation settings"
    )
    model_type: str = Field(..., description="Configured model type")

    class Config:
        from_attributes = True


class RParameterEstimation(BaseModel):
    """R result DTO for parameter estimation step."""

    estimates_path: str = Field(..., description="Path to parameter estimates RDS file")
    standard_errors_path: str = Field(..., description="Path to standard errors")
    covariance_matrix_path: str = Field(..., description="Path to covariance matrix")
    convergence_info_path: str = Field(
        ..., description="Path to convergence information"
    )
    likelihood_value: float = Field(..., description="Final likelihood value")
    iterations: int = Field(..., description="Number of iterations")

    class Config:
        from_attributes = True


class RConvergenceCheck(BaseModel):
    """R result DTO for convergence check step."""

    convergence_results_path: str = Field(
        ..., description="Path to convergence check results"
    )
    gradient_check_path: str = Field(..., description="Path to gradient check results")
    hessian_check_path: str = Field(..., description="Path to Hessian check results")
    converged: bool = Field(..., description="Whether the model converged")

    class Config:
        from_attributes = True


class RResultsSummary(BaseModel):
    """R result DTO for results summary step."""

    summary_table_path: str = Field(..., description="Path to results summary table")
    coefficient_table_path: str = Field(..., description="Path to coefficient table")
    diagnostics_path: str = Field(..., description="Path to model diagnostics")
    confidence_intervals_path: str = Field(
        ..., description="Path to confidence intervals"
    )

    class Config:
        from_attributes = True


class RExportEstimates(BaseModel):
    """R result DTO for export estimates step."""

    export_file_path: str = Field(..., description="Path to exported estimates file")
    metadata_file_path: str = Field(..., description="Path to metadata file")

    class Config:
        from_attributes = True





# =============================================================================
# RISK MAP MODULE R INTEGRATION DTOs
# =============================================================================


class RRiskCalculation(BaseModel):
    """R result DTO for risk calculation step."""

    risk_estimates_path: str = Field(..., description="Path to risk estimates RDS file")
    confidence_intervals_path: str = Field(
        ..., description="Path to confidence intervals"
    )
    scenario_results_path: str = Field(..., description="Path to scenario results")
    prediction_path: str = Field(..., description="Path to prediction results")

    class Config:
        from_attributes = True


class RSpatialMapping(BaseModel):
    """R result DTO for spatial mapping step."""

    risk_maps_path: str = Field(..., description="Path to risk maps")
    spatial_statistics_path: str = Field(
        ..., description="Path to spatial statistics RDS file"
    )
    map_metadata_path: str = Field(..., description="Path to map metadata")
    confidence_maps_path: str = Field(..., description="Path to confidence maps")

    class Config:
        from_attributes = True


class RThresholdAnalysis(BaseModel):
    """R result DTO for threshold analysis step."""

    threshold_statistics_path: str = Field(
        ..., description="Path to threshold statistics RDS file"
    )
    exceedance_probabilities_path: str = Field(
        ..., description="Path to exceedance probabilities"
    )
    threshold_maps_path: str = Field(..., description="Path to threshold maps")
    spatial_aggregation_path: str = Field(
        ..., description="Path to spatial aggregation results"
    )

    class Config:
        from_attributes = True


class RRiskVisualization(BaseModel):
    """R result DTO for risk visualization step."""

    visualizations_path: str = Field(..., description="Path to visualizations")
    interactive_plots_path: str = Field(..., description="Path to interactive plots")
    animation_files_path: str = Field(..., description="Path to animation files")

    class Config:
        from_attributes = True


class RExportRiskMaps(BaseModel):
    """R result DTO for export risk maps step."""

    export_files_path: str = Field(..., description="Path to exported files")
    archive_path: str = Field(..., description="Path to archive file")
    metadata_files_path: str = Field(..., description="Path to metadata files")

    class Config:
        from_attributes = True
