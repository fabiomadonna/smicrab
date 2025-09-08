export interface ValidateModuleFile {
  name: string;
  path_dynamic?: string;
  path_static?: string;
  function?: string;
  description?: string;
}

export interface ResidualSummaryStatistics {
  description: string;
  files: ValidateModuleFile[];
}

export interface AutocorrelationTests {
  description: string;
  files: ValidateModuleFile[];
}

export interface NormalityTests {
  description: string;
  files: ValidateModuleFile[];
}

export interface BootstrapComparison {
  description: string;
  files: ValidateModuleFile[];
}

export interface ParameterDistribution {
  description: string;
  files: ValidateModuleFile[];
}

export interface BootstrapValidation {
  description: string;
  bootstrap_comparison: BootstrapComparison;
  parameter_distribution: ParameterDistribution;
}

export interface ValidateModuleOutputs {
  residual_summary_statistics: ResidualSummaryStatistics;
  autocorrelation_tests: AutocorrelationTests;
  normality_tests: NormalityTests;
  bootstrap_validation: BootstrapValidation;
}

export interface ValidateModelAvailability {
  residual_summary_statistics: boolean;
  autocorrelation_tests: boolean;
  normality_tests: boolean;
  bootstrap_validation: boolean;
}

export interface ValidateModelSpecificAvailability {
  Model1_Simple: ValidateModelAvailability;
  Model2_Autoregressive: ValidateModelAvailability;
  Model3_MB_User: ValidateModelAvailability;
  Model4_UHI: ValidateModelAvailability;
  Model5_RAB: ValidateModelAvailability;
  Model6_HSDPD_user: ValidateModelAvailability;
}

export interface GetValidateOutputsResponse {
  validate_module_outputs: ValidateModuleOutputs;
  model_specific_availability: ValidateModelSpecificAvailability;
} 