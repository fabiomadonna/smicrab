import { AnalysisVariable } from './enums';

export interface DescribeModuleFile {
  name: string;
  variable?: AnalysisVariable;
  path_dynamic?: string;
  path_static?: string;
  function?: string;
  description?: string;
}

export interface DescribeModuleDataExports {
  endogenous_variable_csv: string;
}

export interface DescribeModulePlotGroup {
  description: string;
  files: DescribeModuleFile[];
}

export interface DescribeModuleStatistics {
  variable_summary_statistics: string;
  pixel_time_series_data: string;
}

export interface DescribeModuleOutputs {
  data_exports: DescribeModuleDataExports;
  spatial_distribution_plots: DescribeModulePlotGroup;
  temporal_distribution_plots: DescribeModulePlotGroup;
  summary_statistics_plots: DescribeModulePlotGroup;
  statistics_data: DescribeModuleStatistics;
}

export interface ModelAvailability {
  data_exports: boolean;
  spatial_distribution_plots: boolean;
  temporal_distribution_plots: boolean;
  summary_statistics_plots: boolean;
  statistics_data: boolean;
}

export interface ModelSpecificAvailability {
  Model1_Simple: ModelAvailability;
  Model2_Autoregressive: ModelAvailability;
  Model3_MB_User: ModelAvailability;
  Model4_UHI: ModelAvailability;
  Model5_RAB: ModelAvailability;
  Model6_HSDPD_user: ModelAvailability;
}

export interface GetDescribeModuleOutputsResponse {
  describe_module_outputs: DescribeModuleOutputs;
  model_specific_availability: ModelSpecificAvailability;
} 