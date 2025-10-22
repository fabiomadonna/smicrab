import { ModelType } from "./enums";

// Risk map module file interface
export interface RiskMapModuleFile {
  name: string;
  path_dynamic?: string;
  path_static?: string;
  function?: string;
  description?: string;
}

// Risk map test category interface
export interface RiskMapTestCategory {
  description: string;
  files: RiskMapModuleFile[];
}

// Risk map module outputs interface
export interface RiskMapModuleOutputs {
  sens_slope_test: RiskMapTestCategory;
  cox_snell_test: RiskMapTestCategory;
  mann_kendall_test: RiskMapTestCategory;
  seasonal_mann_kendall_test: RiskMapTestCategory;
  prewhitened_mann_kendall_test: RiskMapTestCategory;
  bias_corrected_prewhitened_test: RiskMapTestCategory;
  robust_trend_newey_west: RiskMapTestCategory;
  score_function_combination: RiskMapTestCategory;
  majority_voting_combination: RiskMapTestCategory;
  temporal_analysis: RiskMapTestCategory;
  spatial_analysis: RiskMapTestCategory;
  spatiotemporal_trend_analysis: RiskMapTestCategory;
  spatial_regression_trend_parameters: RiskMapTestCategory;
  spatiotemporal_fixed_effects_analysis: RiskMapTestCategory;
  spatial_regression_fixed_effect_parameters: RiskMapTestCategory;
}

// Model availability interface for risk map features
export interface RiskMapModelAvailability {
  sens_slope_test: boolean;
  cox_snell_test: boolean;
  mann_kendall_test: boolean;
  seasonal_mann_kendall_test: boolean;
  prewhitened_mann_kendall_test: boolean;
  bias_corrected_prewhitened_test: boolean;
  robust_trend_newey_west: boolean;
  score_function_combination: boolean;
  majority_voting_combination: boolean;
  temporal_analysis: boolean;
  spatial_analysis: boolean;
  spatiotemporal_trend_analysis: boolean;
  spatial_regression_trend_parameters: boolean;
  spatiotemporal_fixed_effects_analysis: boolean;
  spatial_regression_fixed_effect_parameters: boolean;
}

// Model specific availability interface - backend uses string keys
export interface RiskMapModelSpecificAvailability {
  Model1_Simple: RiskMapModelAvailability;
  Model2_Autoregressive: RiskMapModelAvailability;
  Model3_MB_User: RiskMapModelAvailability;
  Model4_UHI: RiskMapModelAvailability;
  Model5_RAB: RiskMapModelAvailability;
  Model6_HSDPD_user: RiskMapModelAvailability;
}

// Get risk map outputs response interface
export interface GetRiskMapOutputsResponse {
  riskmap_module_outputs: RiskMapModuleOutputs;
  model_specific_availability: RiskMapModelSpecificAvailability;
}

// Request interface for getting risk map outputs
export interface GetRiskMapOutputsRequest {
  analysis_id: string;
} 