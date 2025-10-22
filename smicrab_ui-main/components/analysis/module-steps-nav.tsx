"use client";

import React from 'react';
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Card } from "@/components/ui/card";
import { CheckCircle, Circle, Clock, AlertCircle } from "lucide-react";
import { ModuleName, LoadStep, StepProgressStatus } from "@/types";
import { cn } from "@/lib/utils";
import Link from 'next/link';

interface ModuleStep {
  step: string;
  label: string;
  description?: string;
  status: StepProgressStatus;
  isComplete: boolean;
  isCurrent: boolean;
}

interface ModuleStepsNavProps {
  analysisId: string;
  module: ModuleName;
  currentStep: string;
  steps: ModuleStep[];
}

export function ModuleStepsNav({
  analysisId,
  module,
  currentStep,
  steps,
}: ModuleStepsNavProps) {
  
  const getStepIcon = (step: ModuleStep) => {
    if (step.isComplete) {
      return <CheckCircle className="h-5 w-5 text-green-600" />;
    }
    
    if (step.isCurrent) {
      switch (step.status) {
        case StepProgressStatus.IN_PROGRESS:
          return <Clock className="h-5 w-5 text-blue-600 animate-pulse" />;
        case StepProgressStatus.ERROR:
          return <AlertCircle className="h-5 w-5 text-red-600" />;
        default:
          return <Circle className="h-5 w-5 text-blue-600 fill-blue-600" />;
      }
    }
    
    return <Circle className="h-5 w-5 text-muted-foreground" />;
  };

  const getStepStatusColor = (step: ModuleStep) => {
    if (step.isComplete) return "text-green-600";
    if (step.isCurrent) {
      switch (step.status) {
        case StepProgressStatus.ERROR:
          return "text-red-600";
        case StepProgressStatus.IN_PROGRESS:
          return "text-blue-600";
        default:
          return "text-blue-600";
      }
    }
    return "text-muted-foreground";
  };

  const getProgressPercentage = () => {
    const completedSteps = steps.filter(step => step.isComplete).length;
    return (completedSteps / steps.length) * 100;
  };

  const canNavigateToStep = (step: ModuleStep, index: number) => {
    // Can navigate to completed steps or current step
    if (step.isComplete || step.isCurrent) return true;
    
    // Can navigate to the next step if all previous steps are complete
    const previousSteps = steps.slice(0, index);
    return previousSteps.every(prevStep => prevStep.isComplete);
  };

  return (
    <Card className="p-6">
      <div className="space-y-6">
        {/* Progress Header */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold">Module Progress</h3>
            <Badge variant="outline" className="text-xs">
              {steps.filter(step => step.isComplete).length} of {steps.length} completed
            </Badge>
          </div>
          <Progress value={getProgressPercentage()} className="h-2" />
        </div>

        {/* Steps Navigation */}
        <div className="space-y-1">
          {steps.map((step, index) => (
            <div key={step.step} className="flex items-center space-x-3">
              {/* Step Icon */}
              <div className="flex-shrink-0">
                {getStepIcon(step)}
              </div>

              {/* Step Content */}
              <div className="flex-1 min-w-0">
                <Button
                  variant="ghost"
                  className={cn(
                    "w-full justify-start h-auto p-3 text-left",
                    step.isCurrent && "bg-accent/50",
                    !canNavigateToStep(step, index) && "opacity-50 cursor-not-allowed"
                  )}
                  disabled={!canNavigateToStep(step, index)}
                  asChild={canNavigateToStep(step, index)}
                >
                  {canNavigateToStep(step, index) ? (
                    <Link href={`/analysis/${analysisId}/${module}/${step.step}`}>
                      <div className="space-y-1">
                        <div className="flex items-center space-x-2">
                          <span className={cn(
                            "font-medium",
                            getStepStatusColor(step)
                          )}>
                            {step.label}
                          </span>
                          {step.isCurrent && (
                            <Badge variant="secondary" className="text-xs">
                              Current
                            </Badge>
                          )}
                          {step.status === StepProgressStatus.ERROR && (
                            <Badge variant="destructive" className="text-xs">
                              Error
                            </Badge>
                          )}
                        </div>
                        {step.description && (
                          <p className="text-sm text-muted-foreground">
                            {step.description}
                          </p>
                        )}
                      </div>
                    </Link>
                  ) : (
                    <div className="space-y-1">
                      <div className="flex items-center space-x-2">
                        <span className={cn(
                          "font-medium",
                          getStepStatusColor(step)
                        )}>
                          {step.label}
                        </span>
                      </div>
                      {step.description && (
                        <p className="text-sm text-muted-foreground">
                          {step.description}
                        </p>
                      )}
                    </div>
                  )}
                </Button>
              </div>

              {/* Step Number */}
              <div className="flex-shrink-0">
                <div className={cn(
                  "w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium",
                  step.isComplete ? "bg-green-100 text-green-800" :
                  step.isCurrent ? "bg-blue-100 text-blue-800" :
                  "bg-muted text-muted-foreground"
                )}>
                  {index + 1}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Status Summary */}
        <div className="pt-4 border-t">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">
              Current Step: <span className="font-medium">{currentStep}</span>
            </span>
            <span className="text-muted-foreground">
              Progress: {Math.round(getProgressPercentage())}%
            </span>
          </div>
        </div>
      </div>
    </Card>
  );
} 