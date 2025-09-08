export interface EstimateModuleFile {
  name: string;
  path_dynamic?: string;
  path_static?: string;
  function?: string;
  description?: string;
}

export interface CoefficientTables {
  description: string;
  files: EstimateModuleFile[];
}

export interface CoefficientPlots {
  description: string;
  trend_plots: EstimateModuleFile[];
  covariate_plots: EstimateModuleFile[];
  spatial_autocorrelation_plots: EstimateModuleFile[];
  fixed_effects_plots: EstimateModuleFile[];
}

export interface TimeSeriesPlots {
  description: string;
  files: EstimateModuleFile[];
}

export interface CsvDownloads {
  description: string;
  files: EstimateModuleFile[];
}

export interface EstimateModuleOutputs {
  coefficient_tables: CoefficientTables;
  coefficient_plots: CoefficientPlots;
  time_series_plots: TimeSeriesPlots;
  csv_downloads: CsvDownloads;
}

export interface EstimateModelAvailability {
  coefficient_tables: boolean;
  coefficient_plots: boolean;
  time_series_plots: boolean;
  csv_downloads: boolean;
}

export interface EstimateModelSpecificAvailability {
  Model1_Simple: EstimateModelAvailability;
  Model2_Autoregressive: EstimateModelAvailability;
  Model3_MB_User: EstimateModelAvailability;
  Model4_UHI: EstimateModelAvailability;
  Model5_RAB: EstimateModelAvailability;
  Model6_HSDPD_user: EstimateModelAvailability;
}

// Backend returns GetEstimateOutputsResponse directly in data field
export interface GetEstimateModuleOutputsResponse {
  estimate_module_outputs: EstimateModuleOutputs;
  model_specific_availability: EstimateModelSpecificAvailability;
} 