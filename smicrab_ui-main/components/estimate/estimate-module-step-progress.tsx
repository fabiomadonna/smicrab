 "use client";

import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";
import { EstimateStep } from "@/types/enums";

interface EstimateModuleStepProgressProps {
  currentStep: string;
  title?: string;
}

export function EstimateModuleStepProgress({
  currentStep,
  title = "Estimate Module Progress"
}: EstimateModuleStepProgressProps) {
  // Define steps for the estimate module
  const steps = [
    { step: EstimateStep.MODEL_SETUP, label: "Model Setup" },
    { step: EstimateStep.PARAMETER_ESTIMATION, label: "Parameter Estimation" },
    { step: EstimateStep.CONVERGENCE_CHECK, label: "Convergence Check" },
    { step: EstimateStep.RESULTS_SUMMARY, label: "Results Summary" },
    { step: EstimateStep.EXPORT_ESTIMATES, label: "Export Estimates" }
  ];
  
  const currentStepIndex = steps.findIndex(s => s.step === currentStep);
  const completedSteps = currentStepIndex;
  const progressPercentage = (completedSteps / (steps.length - 1)) * 100;
  
  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center space-y-4 mb-8">
        <div className="flex items-center justify-center space-x-4">
          <Badge variant="outline">
            Step {currentStepIndex + 1} of {steps.length}
          </Badge>
          <Badge variant="secondary" className="text-xs">
            {steps.find(s => s.step === currentStep)?.label || currentStep}
          </Badge>
        </div>
        
        <div className="space-y-2">
          <h2 className="text-xl font-semibold">{title}</h2>
          <div className="w-full max-w-md mx-auto">
            <Progress value={progressPercentage} className="h-2" />
          </div>
        </div>
      </div>
      
      <div className="flex justify-center mb-8 overflow-auto">
        <div className="flex items-center space-x-2">
          {steps.map((step, index) => (
            <div key={step.step} className="flex items-center">
              <div
                className={cn(
                  "w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium",
                  index < currentStepIndex
                    ? "bg-green-500 text-white"
                    : index === currentStepIndex
                    ? "bg-orange-500 text-white"
                    : "bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-300"
                )}
              >
                {index + 1}
              </div>
              {index < steps.length - 1 && (
                <div 
                  className={cn(
                    "w-8 h-0.5 mx-2",
                    index < currentStepIndex 
                      ? "bg-green-500" 
                      : "bg-gray-200 dark:bg-gray-700"
                  )}
                />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}