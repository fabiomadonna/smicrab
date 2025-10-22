// Core business types for SMICRAB GUI components

import { 
  StepProgressStatus, 
  ModuleName, 
  LoadStep,
  DescribeStep,
  EstimateStep,
  ValidateStep,
  RiskMapStep
} from './enums';

// Date and time types
export interface DateRange {
  from: string;
  to: string;
}

// Model configuration types
export interface ModelConfiguration {
  endogenous: string | null;
  exogenous: Array<{
    variable: string;
    xLag: number;
  }>;
}

// Data processing types
export interface BuildOptions {
  px_core: number;
  px_neighbors: number;
  t_frequency: number;
  na_rm: boolean;
  groups: number;
  NAcovs: string;
}

export interface DataFrameOptions {
  px_core: number;
  px_neighbors: number;
  t_frequency: number;
  na_rm: boolean;
  groups: number;
  na_covs: string;
}

// Download and export types
export interface DownloadVariable {
  id: string;
  name: string;
  include: boolean;
  fileName?: string;
}

// Plot and visualization types
export interface PlotConfiguration {
  statistic: 'mean' | 'sd' | 'min' | 'max';
  colorPalette: string;
  plotType: number; // 1-7
}

export interface PixelSelection {
  latitude: number;
  longitude: number;
  plotType: number; // 1-6
  dateRange?: DateRange;
}

export interface SeriesData {
  latitude: number[];
  longitude: number[];
  group: string[];
  time_series: { [key: string]: number[] };
}

export interface StatsPlotData {
  latitude: number[];
  longitude: number[];
  values: number[];
  variable: string;
}

// Module step unions for routing
export type ModuleStep = LoadStep | DescribeStep | EstimateStep | ValidateStep | RiskMapStep;

// Analysis navigation types
export interface AnalysisNavigation {
  analysisId: string;
  module: ModuleName;
  step: ModuleStep;
}

// Module configuration for UI
export interface ModuleConfig {
  name: ModuleName;
  displayName: string;
  steps: { value: ModuleStep; label: string; description?: string }[];
  isCompleted: boolean;
  currentStep?: ModuleStep;
}

// Workflow and progress types
export type WorkflowStep = 'start' | 'load_module' | 'describe_module' | 'estimate_module' | 'validate_module' | 'risk_map_module' | 'end';

export interface ModuleResult {
  success: boolean;
  data?: any;
  error?: string;
} 