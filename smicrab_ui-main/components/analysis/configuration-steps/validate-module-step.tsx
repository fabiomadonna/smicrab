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
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Info, CheckCircle, Settings } from "lucide-react";
import { AnalysisFormData, VectorOptions } from "@/types/analysis";

interface StepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
  isLastStep?: boolean;
  onSubmit?: (data: Partial<AnalysisFormData>) => void;
}

export function ValidateModuleStep({
  formData,
  onNext,
  onPrevious,
  isLoading,
  errors,
}: StepProps) {
  const [vecOptions, setVecOptions] = useState<VectorOptions>(
    formData.vec_options ?? {
      groups: 1,
      px_core: 1,
      px_neighbors: 3,
      t_frequency: 12,
      na_rm: true,
      NAcovs: "pairwise.complete.obs",
    }
  );

  const handleNext = () => {
    const stepData: Partial<AnalysisFormData> = {
      vec_options: vecOptions,
    };
    onNext(stepData);
  };

  const updateVecOptions = (key: keyof VectorOptions, value: any) => {
    setVecOptions((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-lg">
            <Settings className="w-4 h-4" />
            Vector Options
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="groups" className="text-sm font-medium">
                Groups
              </Label>
              <Input
                id="groups"
                type="number"
                min="1"
                value={vecOptions.groups}
                onChange={(e) =>
                  updateVecOptions("groups", parseInt(e.target.value))
                }
                className={errors?.groups ? "border-red-500" : ""}
              />
              {errors?.groups && (
                <p className="text-xs text-red-500">{errors.groups}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="px_core" className="text-sm font-medium">
                Core Pixels
              </Label>
              <Input
                id="px_core"
                type="number"
                min="1"
                value={vecOptions.px_core}
                onChange={(e) =>
                  updateVecOptions("px_core", parseInt(e.target.value))
                }
                className={errors?.px_core ? "border-red-500" : ""}
              />
              {errors?.px_core && (
                <p className="text-xs text-red-500">{errors.px_core}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="px_neighbors" className="text-sm font-medium">
                Neighbor Pixels
              </Label>
              <Input
                id="px_neighbors"
                type="number"
                min="1"
                value={vecOptions.px_neighbors}
                onChange={(e) =>
                  updateVecOptions("px_neighbors", parseInt(e.target.value))
                }
                className={errors?.px_neighbors ? "border-red-500" : ""}
              />
              {errors?.px_neighbors && (
                <p className="text-xs text-red-500">{errors.px_neighbors}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="t_frequency" className="text-sm font-medium">
                Time Frequency
              </Label>
              <Input
                id="t_frequency"
                type="number"
                min="1"
                value={vecOptions.t_frequency}
                onChange={(e) =>
                  updateVecOptions("t_frequency", parseInt(e.target.value))
                }
                className={errors?.t_frequency ? "border-red-500" : ""}
              />
              {errors?.t_frequency && (
                <p className="text-xs text-red-500">{errors.t_frequency}</p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <Label htmlFor="na_rm" className="text-sm font-medium">
                  Remove NA Values
                </Label>
                <p className="text-xs text-muted-foreground">
                  Remove missing values from calculations
                </p>
              </div>
              <Switch
                id="na_rm"
                checked={vecOptions.na_rm}
                onCheckedChange={(checked) =>
                  updateVecOptions("na_rm", checked)
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="NAcovs" className="text-sm font-medium">
                NA Covariate Handling
              </Label>
              <Input
                id="NAcovs"
                disabled
                value={vecOptions.NAcovs}
                onChange={(e) => updateVecOptions("NAcovs", e.target.value)}
                placeholder="pairwise.complete.obs"
                className={errors?.NAcovs ? "border-red-500" : ""}
              />
              {errors?.NAcovs && (
                <p className="text-xs text-red-500">{errors.NAcovs}</p>
              )}
            </div>
          </div>

          <div className="p-3 bg-muted rounded-md text-sm mt-8">
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              <div>Groups: {vecOptions.groups}</div>
              <div>Core: {vecOptions.px_core}</div>
              <div>Neighbors: {vecOptions.px_neighbors}</div>
              <div>Frequency: {vecOptions.t_frequency}</div>
              <div>Remove NA: {vecOptions.na_rm ? "Yes" : "No"}</div>
              <div>NA Method: {vecOptions.NAcovs}</div>
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
        <Button onClick={handleNext} disabled={isLoading}>
          Next: Risk Map Module
        </Button>
      </div>
    </div>
  );
}
