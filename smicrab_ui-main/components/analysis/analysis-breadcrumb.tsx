"use client";

import { Fragment } from "react";
import Link from "next/link";
import { ChevronRight, Home } from "lucide-react";
import { ModuleName } from "@/types";

interface AnalysisBreadcrumbProps {
  analysisId: string;
  currentModule?: ModuleName;
  currentStep?: string;
}

export function AnalysisBreadcrumb({
  analysisId,
  currentModule,
  currentStep,
}: AnalysisBreadcrumbProps) {
  const getModuleName = (module: ModuleName): string => {
    switch (module) {
      case ModuleName.DESCRIBE_MODULE:
        return 'Describe Module';
      case ModuleName.ESTIMATE_MODULE:
        return 'Estimate Module';
      case ModuleName.VALIDATE_MODULE:
        return 'Validate Module';
      case ModuleName.RISK_MAP_MODULE:
        return 'Risk Map Module';
      default:
        return 'Configuration';
    }
  };

  const getStepName = (step: string): string => {
    switch (step) {
      case 'configure':
        return 'Configuration';
      case 'results':
        return 'Results';
      case 'data_summary':
        return 'Data Summary';
      case 'correlation_analysis':
        return 'Correlation Analysis';
      case 'distribution_analysis':
        return 'Distribution Analysis';
      case 'time_series_plots':
        return 'Time Series Plots';
      case 'spatial_plots':
        return 'Spatial Plots';
      case 'export_results':
        return 'Export Results';
      case 'model_setup':
        return 'Model Setup';
      case 'parameter_estimation':
        return 'Parameter Estimation';
      case 'convergence_check':
        return 'Convergence Check';
      case 'results_summary':
        return 'Results Summary';
      case 'export_estimates':
        return 'Export Estimates';
      case 'residual_analysis':
        return 'Residual Analysis';
      case 'diagnostic_tests':
        return 'Diagnostic Tests';
      case 'model_performance':
        return 'Model Performance';
      case 'goodness_of_fit':
        return 'Goodness of Fit';
      case 'validation_report':
        return 'Validation Report';
      case 'risk_calculation':
        return 'Risk Calculation';
      case 'spatial_mapping':
        return 'Spatial Mapping';
      case 'threshold_analysis':
        return 'Threshold Analysis';
      case 'risk_visualization':
        return 'Risk Visualization';
      case 'export_risk_maps':
        return 'Export Risk Maps';
      default:
        return step;
    }
  };

  return (
    <nav className="flex items-center space-x-1 text-sm text-muted-foreground mb-6">
      <Link
        href="/"
        className="hover:text-foreground transition-colors"
      >
        <Home className="h-4 w-4" />
      </Link>
      
      <ChevronRight className="h-4 w-4" />
      
      <Link
        href="/analyses"
        className="hover:text-foreground transition-colors"
      >
        Analyses
      </Link>
      
      <ChevronRight className="h-4 w-4" />
      
      <Link
        href={`/analysis/${analysisId}`}
        className="hover:text-foreground transition-colors"
      >
        Analysis {analysisId.slice(-8)}
      </Link>
      
      {currentModule && (
        <Fragment>
          <ChevronRight className="h-4 w-4" />
          <Link
            href={`/analysis/${analysisId}/${currentModule}`}
            className="hover:text-foreground transition-colors"
          >
            {getModuleName(currentModule)}
          </Link>
        </Fragment>
      )}
      
      {currentStep && (
        <Fragment>
          <ChevronRight className="h-4 w-4" />
          <span className="text-foreground font-medium">
            {getStepName(currentStep)}
          </span>
        </Fragment>
      )}
    </nav>
  );
} 