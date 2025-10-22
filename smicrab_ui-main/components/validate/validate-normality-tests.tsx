"use client";

import { PlotGroup } from "@/components/ui/plot-group";
import { NormalityTests } from "@/types/validate";

interface ValidateNormalityTestsProps {
  data: NormalityTests;
  analysisId: string;
  isDynamic: boolean;
}

export function ValidateNormalityTests({
  data,
  analysisId,
  isDynamic,
}: ValidateNormalityTestsProps) {
  return (
    <PlotGroup
      title="Normality Tests"
      description={data.description}
      files={data.files}
      analysisId={analysisId}
      isDynamic={isDynamic}
      showFunctionInfo={true}
    />
  );
} 