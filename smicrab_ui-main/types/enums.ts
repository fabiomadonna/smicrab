export enum AnalyzeStatus {
  PENDING = "pending",
  CONFIGURED = "configured",
  IN_PROGRESS = "in_progress",
  COMPLETED = "completed",
  ERROR = "error"
}

export enum StepProgressStatus {
  PENDING = "pending",
  IN_PROGRESS = "in_progress",
  COMPLETED = "completed",
  ERROR = "error"
}

export enum ModuleName {
  LOAD_MODULE = "load_module",
  DESCRIBE_MODULE = "describe_module",
  ESTIMATE_MODULE = "estimate_module",
  VALIDATE_MODULE = "validate_module",
  RISK_MAP_MODULE = "risk_map_module"
}

export enum ModelType {
  MODEL1_SIMPLE = "Model1_Simple",
  MODEL2_AUTOREGRESSIVE = "Model2_Autoregressive",
  MODEL3_MB_USER = "Model3_MB_User",
  Model4_UHI = "Model4_UHI",
  MODEL5_RAB = "Model5_RAB",
  MODEL6_HSDPD_USER = "Model6_HSDPD_user"
}

export enum AnalysisVariable {
  MAXIMUM_AIR_TEMPERATURE_ADJUSTED = "maximum_air_temperature_adjusted",
  MEAN_AIR_TEMPERATURE_ADJUSTED = "mean_air_temperature_adjusted",
  MINIMUM_AIR_TEMPERATURE_ADJUSTED = "minimum_air_temperature_adjusted",
  MEAN_RELATIVE_HUMIDITY_ADJUSTED = "mean_relative_humidity_adjusted",
  ACCUMULATED_PRECIPITATION_ADJUSTED = "accumulated_precipitation_adjusted",
  MEAN_WIND_SPEED_ADJUSTED = "mean_wind_speed_adjusted",
  BLACK_SKY_ALBEDO_ALL_MEAN = "black_sky_albedo_all_mean",
  LST_H18 = "LST_h18"
}

export enum SummaryStat {
  MEAN = "mean",
  STANDARD_DEVIATION = "standard_deviation",
  MIN = "min",
  MAX = "max",
  MEDIAN = "median",
  RANGE = "range",
  COUNT_NAS = "count.NAs"
}

export enum LoadStep {
  START = "start",
  MODEL_CONFIG = "model_config",
  BUILD_DATAFRAME = "build_dataframe",
  SELECT_VARIABLE = "select_variable",
  DOWNLOAD = "download",
  DONE = "done"
}

export enum DescribeStep {
  DATA_SUMMARY = "data_summary",
  CORRELATION_ANALYSIS = "correlation_analysis",
  DISTRIBUTION_ANALYSIS = "distribution_analysis",
  TIME_SERIES_PLOTS = "time_series_plots",
  SPATIAL_PLOTS = "spatial_plots",
  EXPORT_RESULTS = "export_results"
}

export enum EstimateStep {
  MODEL_SETUP = "model_setup",
  PARAMETER_ESTIMATION = "parameter_estimation",
  CONVERGENCE_CHECK = "convergence_check",
  RESULTS_SUMMARY = "results_summary",
  EXPORT_ESTIMATES = "export_estimates"
}

export enum ValidateStep {
  RESIDUAL_ANALYSIS = "residual_analysis",
  DIAGNOSTIC_TESTS = "diagnostic_tests",
  MODEL_PERFORMANCE = "model_performance",
  GOODNESS_OF_FIT = "goodness_of_fit",
  VALIDATION_REPORT = "validation_report"
}

export enum RiskMapStep {
  RISK_CALCULATION = "risk_calculation",
  SPATIAL_MAPPING = "spatial_mapping",
  THRESHOLD_ANALYSIS = "threshold_analysis",
  RISK_VISUALIZATION = "risk_visualization",
  EXPORT_RISK_MAPS = "export_risk_maps"
}

export enum AnalysisType {
  descriptive = "descriptive",
  correlation = "correlation",
  distribution = "distribution",
  time_series = "time_series",
  spatial = "spatial",
}

export enum PlotType {
  histogram = "histogram",
  boxplot = "boxplot",
  scatter = "scatter",
  time_series = "time_series",
  heatmap = "heatmap",
  spatial_map = "spatial_map",
}

export enum ValidationMetric {
  rmse = "rmse",
  mae = "mae",
  mape = "mape",
  r_squared = "r_squared",
  aic = "aic",
  bic = "bic",
}

export enum RiskLevel {
  very_low = "very_low",
  low = "low",
  medium = "medium",
  high = "high",
  very_high = "very_high",
} 