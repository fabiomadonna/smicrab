"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { ChevronLeft, ChevronRight, Save } from "lucide-react";
import { AnalysisFormData, DEFAULT_ANALYSIS_FORM_DATA } from "@/types/analysis";
import { saveAnalysisParametersAction } from "@/actions";
import { AnalysisModuleProgress } from "./analysis-module-progress";
import { ModuleName } from "@/types";

// Step components
import { DataModuleStep } from "./configuration-steps/data-module-step";
import { DescribeModuleStep } from "./configuration-steps/describe-module-step";
import { EstimateModuleStep } from "./configuration-steps/estimate-module-step";
import { ValidateModuleStep } from "./configuration-steps/validate-module-step";
import { RiskMapModuleStep } from "./configuration-steps/risk-map-module-step";
import { useRouter } from "next/navigation";

interface AnalysisConfigurationFormProps {
  analysisId: string;
}

const STEPS = [
  { id: 'data', title: 'Data Module', module: ModuleName.LOAD_MODULE, component: DataModuleStep },
  { id: 'describe', title: 'Describe Module', module: ModuleName.DESCRIBE_MODULE, component: DescribeModuleStep },
  { id: 'estimate', title: 'Estimate Module', module: ModuleName.ESTIMATE_MODULE, component: EstimateModuleStep },
  { id: 'validate', title: 'Validate Module', module: ModuleName.VALIDATE_MODULE, component: ValidateModuleStep },
  { id: 'riskmap', title: 'Risk Map Module', module: ModuleName.RISK_MAP_MODULE, component: RiskMapModuleStep }
];

export function AnalysisConfigurationForm({ analysisId }: AnalysisConfigurationFormProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState<Partial<AnalysisFormData>>(DEFAULT_ANALYSIS_FORM_DATA);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const CurrentStepComponent = STEPS[currentStep].component;

  const handleNext = (stepData: Partial<AnalysisFormData>) => {
    setFormData(prev => ({ ...prev, ...stepData }));
    setErrors({});
    
    if (currentStep < STEPS.length - 1) {
      setCurrentStep(prev => prev + 1);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(prev => prev - 1);
    }
  };

  const handleSubmit = async (finalStepData: Partial<AnalysisFormData>) => {
    setIsSubmitting(true);
    setErrors({});

    try {
      const completeFormData = { ...formData, ...finalStepData } as AnalysisFormData;
      
      // Convert form data to API request format
      const requestData = {
        analysis_id: analysisId,
        model_type: completeFormData.model_type,
        bool_update: completeFormData.bool_update,
        bool_trend: completeFormData.bool_trend,
        summary_stat: completeFormData.summary_stat,
        user_longitude_choice: completeFormData.user_longitude_choice,
        user_latitude_choice: completeFormData.user_latitude_choice,
        user_coeff_choice: completeFormData.user_coeff_choice,
        bool_dynamic: completeFormData.bool_dynamic,
        endogenous_variable: completeFormData.endogenous_variable,
        covariate_variables: completeFormData.covariate_variables,
        covariate_legs: completeFormData.covariate_legs,
        user_date_choice: completeFormData.user_date_choice,
        vec_options: completeFormData.vec_options
      };

      const response = await saveAnalysisParametersAction(requestData);

      if (response.success) {
        toast.success("Analysis configuration saved successfully!");
        // The page will auto-refresh via polling and show the next status
      } else {
        const errorMessage = typeof response.error === 'string' 
          ? response.error 
          : Array.isArray(response.error) 
            ? response.error.map(e => `${e.field}: ${e.message}`).join(', ')
            : "Failed to save configuration";
        
        toast.error(errorMessage);
      }
    } catch (error) {
      console.error("Error saving configuration:", error);
      toast.error("Failed to save configuration");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-4 mt-10">
      {/* Analysis Module Progress */}
      <AnalysisModuleProgress 
        currentModule={STEPS[currentStep].module as ModuleName}
        title="Analysis Configuration"
      />

      {/* Current Step Content */}
      <CurrentStepComponent
        formData={formData}
        onNext={handleNext}
        onPrevious={currentStep > 0 ? handlePrevious : undefined}
        isLoading={isSubmitting}
        errors={errors}
        isLastStep={currentStep === STEPS.length - 1}
        onSubmit={currentStep === STEPS.length - 1 ? handleSubmit : undefined}
      />
    </div>
  );
} 