"use client";

import { useState } from "react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Info, Map, Save, CheckCircle2 } from "lucide-react";
import { AnalysisFormData } from "@/types/analysis";

interface StepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
  isLastStep?: boolean;
  onSubmit?: (data: Partial<AnalysisFormData>) => void;
}

export function RiskMapModuleStep({
  formData,
  onNext,
  onPrevious,
  isLoading,
  errors,
  isLastStep,
  onSubmit,
}: StepProps) {
  const handleSubmit = () => {
    const stepData: Partial<AnalysisFormData> = {};

    if (onSubmit) {
      onSubmit({ ...formData, ...stepData });
    } else {
      onNext(stepData);
    }
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <CheckCircle2 className="w-4 h-4" />
            Configuration Complete
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Model
              </p>
              <p className="font-medium">
                {formData.model_type || "Not selected"}
              </p>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Dependent Variable
              </p>
              <p className="font-medium">
                {formData.endogenous_variable || "Not selected"}
              </p>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Explanatory Variables
              </p>
              <p className="font-medium">
                {formData.covariate_variables?.length || 0} selected
              </p>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Location
              </p>
              <p className="font-medium">
                {formData.user_latitude_choice?.toFixed(2)}°N,{" "}
                {formData.user_longitude_choice?.toFixed(2)}°E
              </p>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Reference Date
              </p>
              <p className="font-medium">
                {formData.user_date_choice
                  ? new Date(formData.user_date_choice).toLocaleDateString()
                  : "Not selected"}
              </p>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <p className="font-medium text-xs text-muted-foreground uppercase">
                Summary Statistic
              </p>
              <p className="font-medium">
                {formData.summary_stat || "Not selected"}
              </p>
            </div>
          </div>

          <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h4 className="font-medium text-blue-900 mb-2 flex items-center gap-2">
              <Map className="w-4 h-4" />
              Next Steps
            </h4>
            <div className="text-sm text-blue-700 space-y-1">
              <p>• Configuration will be saved and validated</p>
              <p>
                • All modules (Data, Describe, Estimate, Validate, Risk Map)
                will execute automatically
              </p>
              <p>• Results, plots, and risk maps will be generated</p>
              <p>• Processing may take several minutes to complete</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={onPrevious}
          disabled={!onPrevious || isLoading}
        >
          Previous
        </Button>
        <Button
          onClick={handleSubmit}
          disabled={isLoading}
          className="text-white bg-green-700 hover:bg-green-800"
        >
          <Save className="w-4 h-4" />
          {isLoading ? "Saving..." : "Complete Configuration"}
        </Button>
      </div>
    </div>
  );
}
