import { 
  AnalyzeStatus,
  StepProgressStatus,
  ModuleName, 
  LoadStep, 
  ModelType
} from './enums';

// Generic API Response type matching backend ResponseDTO
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message: string;
  code?: number;
}

// User Types
export interface CreateUserRequest {
  email: string;
  password: string;
}

export interface CreateUserResponse {
  user_id: string;
  email: string;
  created_at: string;
}

// Analysis Types - moved to analysis.ts to avoid conflicts
export interface AnalysisStatusResponse {
  id: string;
  user_id: string;
  status: AnalyzeStatus;
  current_module: ModuleName;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
  start_date: string;
  end_date: string;
  available_rasters: Raster[];
}

// Dataset Types
export interface Raster {
  id: string;
  name: string;
  variable_name: string;
  from_date: string;
  to_date: string;
  frequency: string;
  file_path: string;
}

export interface Covariate extends Raster {
  x_leg: number;
}

export interface VariableConfiguration {
  id: string;
  x_leg?: number;
}

// Load Module Data Reference Types
export interface ModelConfigData {
  r_path: string;
  max_lag: number;
  metadata: {
    source: string;
    [key: string]: any;
  };
  model_type: ModelType;
  analysis_id: string;
  include_trend: boolean;
  covariate_variables: Covariate[];
  endogenous_variable: Raster;
}

export interface BuildDataframeData {
  na_rm: boolean;
  groups: number;
  r_path: string;
  na_covs: string;
  px_core: number;
  metadata: {
    source: string;
    num_groups: number;
    num_pixels: number;
    time_period: string;
    df_data_path: string;
    df_gruppi_path: string;
    global_series_path: string;
    [key: string]: any;
  };
  t_frequency: number;
  px_neighbors: number;
}

export interface DownloadData {
  r_path: string;
  metadata: {
    source: string;
    csv_files: string[];
    downloads_path: string;
    [key: string]: any;
  };
  selected_variables: Raster[];
}

export interface LoadModuleDataReference {
  model_config?: ModelConfigData;
  build_dataframe?: BuildDataframeData;
  download?: DownloadData;
  [key: string]: any;
}

// Load Module API Types
export interface StartLoadModuleRequest {
  analysis_id: string;
}

export interface StartLoadModuleResponse {
  id: string;
  analysis_id: string;
  current_step: LoadStep;
  step_progress: StepProgressStatus;
  completed: boolean;
  completed_at?: string | null;
  total_steps: number;
  data_reference?: LoadModuleDataReference | null;
  created_at: string;
  updated_at: string;
}

export interface ModelConfigurationRequest {
  analysis_id: string;
  model_type: ModelType;
  endogenous_variable: VariableConfiguration;
  covariate_variables: VariableConfiguration[];
  include_trend: boolean;
}

export interface BuildDataframeRequest {
  analysis_id: string;
  px_core: number;
  px_neighbors: number;
  t_frequency: number;
  na_rm: boolean;
  groups: number;
  na_covs: string;
}

export interface VariableSelectionRequest {
  analysis_id: string;
  variable_selections: string[];
}

export interface CompleteLoadModuleRequest {
  analysis_id: string;
}

export interface LoadModuleStatusResponse {
  id: string;
  analysis_id: string;
  current_step: LoadStep;
  step_progress: StepProgressStatus;
  completed: boolean;
  completed_at?: string;
  data_reference?: LoadModuleDataReference;
}

export interface LoadModuleSchema {
  id: string;
  analysis_id: string;
  current_step: LoadStep;
  step_progress: StepProgressStatus;
  completed: boolean;
  completed_at?: string;
  total_steps: number;
  data_reference?: LoadModuleDataReference;
  created_at: string;
  updated_at: string;
}

// Load Module Step-specific helpers
export interface LoadModuleStepData {
  current_step: LoadStep;
  step_progress: StepProgressStatus;
  data_reference?: LoadModuleDataReference;
}

// Utility types for checking step completion and data availability
export type LoadModuleStepStatus = {
  [K in LoadStep]: {
    completed: boolean;
    data_available: boolean;
  };
};

// Download file information
export interface DownloadFileInfo {
  variable_id: string;
  variable_name: string;
  file_name: string;
  file_path: string;
} 