import enum


# Define ENUM types
class AnalyzeStatus(enum.Enum):
    pending = "pending"
    configured = "configured"
    in_progress = "in_progress"
    completed = "completed"
    error = "error"


class StepProgressStatus(enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"
    error = "error"


class ModuleName(enum.Enum):
    load_module = "load_module"
    describe_module = "describe_module"
    estimate_module = "estimate_module"
    validate_module = "validate_module"
    risk_map_module = "risk_map_module"


class ModuleProgress(enum.Enum):
    init_module = "init_module"
    load_module = "load_module"
    describe_module = "describe_module"
    estimate_module = "estimate_module"
    validate_module = "validate_module"
    risk_map_module = "risk_map_module"


class LoadStep(enum.Enum):
    start = "start"
    model_config = "model_config"
    build_dataframe = "build_dataframe"
    select_variable = "select_variable"
    download = "download"
    done = "done"


class DescribeStep(enum.Enum):
    data_summary = "data_summary"
    correlation_analysis = "correlation_analysis"
    distribution_analysis = "distribution_analysis"
    time_series_plots = "time_series_plots"
    spatial_plots = "spatial_plots"
    export_results = "export_results"


class EstimateStep(enum.Enum):
    model_setup = "model_setup"
    parameter_estimation = "parameter_estimation"
    convergence_check = "convergence_check"
    results_summary = "results_summary"
    export_estimates = "export_estimates"


class ValidateStep(enum.Enum):
    residual_analysis = "residual_analysis"
    diagnostic_tests = "diagnostic_tests"
    model_performance = "model_performance"
    goodness_of_fit = "goodness_of_fit"
    validation_report = "validation_report"


class RiskMapStep(enum.Enum):
    risk_calculation = "risk_calculation"
    spatial_mapping = "spatial_mapping"
    threshold_analysis = "threshold_analysis"
    risk_visualization = "risk_visualization"
    export_risk_maps = "export_risk_maps"


class ModelType(enum.Enum):
    Model1_Simple = "Model1_Simple"
    Model2_Autoregressive = "Model2_Autoregressive"
    Model3_MB_User = "Model3_MB_User"
    Model4_UHI = "Model4_UHI"
    Model5_RAB = "Model5_RAB"
    Model6_HSDPD_user = "Model6_HSDPD_user"


class AnalysisType(enum.Enum):
    descriptive = "descriptive"
    correlation = "correlation"
    distribution = "distribution"
    time_series = "time_series"
    spatial = "spatial"


class PlotType(enum.Enum):
    histogram = "histogram"
    boxplot = "boxplot"
    scatter = "scatter"
    time_series = "time_series"
    heatmap = "heatmap"
    spatial_map = "spatial_map"


class ValidationMetric(enum.Enum):
    rmse = "rmse"
    mae = "mae"
    mape = "mape"
    r_squared = "r_squared"
    aic = "aic"
    bic = "bic"


class RiskLevel(enum.Enum):
    very_low = "very_low"
    low = "low"
    medium = "medium"
    high = "high"
    very_high = "very_high"


class AnalysisVariable(enum.Enum):
    """Enum for analysis variables used in SMICRAB models."""

    maximum_air_temperature_adjusted = "maximum_air_temperature_adjusted"
    mean_air_temperature_adjusted = "mean_air_temperature_adjusted"
    minimum_air_temperature_adjusted = "minimum_air_temperature_adjusted"
    mean_relative_humidity_adjusted = "mean_relative_humidity_adjusted"
    accumulated_precipitation_adjusted = "accumulated_precipitation_adjusted"
    mean_wind_speed_adjusted = "mean_wind_speed_adjusted"
    black_sky_albedo_all_mean = "black_sky_albedo_all_mean"
    LST_h18 = "LST_h18"

    @classmethod
    def get_all_variables(cls):
        """
        Returns the values that should match dataset.variable_name (with overrides if needed).
        """
        variable_mapping = {
            cls.LST_h18.value: "LST",  # Override name for DB value
        }

        return [variable_mapping.get(v.value, v.value) for v in cls]


class SummaryStat(enum.Enum):
    """Enum for summary statistics used in SMICRAB analysis."""

    MEAN = "mean"
    STANDARD_DEVIATION = "standard_deviation"
    MIN = "min"
    MAX = "max"
    MEDIAN = "median"
    RANGE = "range"
    COUNT_NAS = "count.NAs"

    @classmethod
    def get_all_stats(cls) -> list:
        """Return a list of all summary statistic names."""
        return [stat.value for stat in cls]
