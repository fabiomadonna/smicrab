import { 
  AnalyzeStatus, 
  ModuleName, 
  ModelType, 
  AnalysisVariable, 
  SummaryStat 
} from './enums';

// Re-export enums for convenience
export { AnalyzeStatus, ModuleName, ModelType, AnalysisVariable, SummaryStat };

export interface VectorOptions {
  groups: number;
  px_core: number;
  px_neighbors: number;
  t_frequency: number;
  na_rm: boolean;
  NAcovs: string;
}

export interface Analysis {
  id: string;
  user_id: string;
  status: AnalyzeStatus;
  current_module: ModuleName;
  model_config_data?: Record<string, any>;
  model_type?: ModelType;
  coordinates?: Record<string, any>;
  is_dynamic_output?: boolean;
  analysis_date?: string;
  expires_at?: string;
  created_at: string;
  updated_at: string;
  error_message?: string;
}

export interface CreateAnalysisRequest {
  user_id: string;
}

// Backend returns AnalysisSchema directly in data field
export interface CreateAnalysisResponseData {
  analysis: Analysis;
}

// Backend returns UserAnalysesResponse which contains analyses array
export interface UserAnalysesResponseData {
  analyses: Analysis[];
}

export interface SaveAnalysisParametersRequest {
  analysis_id: string;
  model_type: ModelType;
  bool_update: boolean;
  bool_trend: boolean;
  summary_stat: SummaryStat;
  user_longitude_choice: number;
  user_latitude_choice: number;
  user_coeff_choice: number;
  bool_dynamic: boolean;
  endogenous_variable: AnalysisVariable;
  covariate_variables: AnalysisVariable[];
  covariate_legs?: number[];
  user_date_choice?: string;
  vec_options: VectorOptions;
}

// Backend returns AnalysisSchema directly in data field
export interface SaveAnalysisParametersResponseData {
  analysis: Analysis;
}

export interface RunAnalysisRequest {
  analysis_id: string;
}

// Backend returns RunAnalysisResponse directly in data field
export interface RunAnalysisResponseData {
  analysis_id: string;
  status: AnalyzeStatus;
  execution_started: boolean;
  message: string;
}

// Backend returns DeleteAnalysisResponse directly in data field
export interface DeleteAnalysisResponseData {
  analysis_id: string;
  deleted: boolean;
  container_stopped: boolean;
  message: string;
}

// Form data types for the multi-step form
export interface AnalysisFormData {
  // Step 1: Basic Configuration
  model_type: ModelType;
  bool_update: boolean;
  bool_trend: boolean;
  summary_stat: SummaryStat;
  bool_dynamic: boolean;
  
  // Step 2: Geographic Configuration
  user_longitude_choice: number;
  user_latitude_choice: number;
  user_coeff_choice: number;
  
  // Step 3: Variable Selection
  endogenous_variable: AnalysisVariable;
  covariate_variables: AnalysisVariable[];
  covariate_legs: number[];
  // Step 4: Advanced Options
  user_date_choice?: string;
  vec_options: VectorOptions;
}

export interface AnalysisStepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
}

// Default values for form
export const DEFAULT_ANALYSIS_FORM_DATA: AnalysisFormData = {
  model_type: ModelType.MODEL6_HSDPD_USER,
  bool_update: true,
  bool_trend: true,
  summary_stat: SummaryStat.MEAN,
  bool_dynamic: true,
  user_longitude_choice: 11.2,
  user_latitude_choice: 45.1,
  user_coeff_choice: 1.0,
  endogenous_variable: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED,
  covariate_variables: [],
  covariate_legs: [],
  vec_options: {
    groups: 1,
    px_core: 1,
    px_neighbors: 3,
    t_frequency: 12,
    na_rm: true,
    NAcovs: "pairwise.complete.obs",
  },
};

export const DEFAULT_VEC_OPTIONS: VectorOptions = {
  groups: 1,
  px_core: 1,
  px_neighbors: 3,
  t_frequency: 12,
  na_rm: true,
  NAcovs: "pairwise.complete.obs"
}; 