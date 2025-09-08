"use client";

import { PlotGroup } from "@/components/ui/plot-group";
import { AutocorrelationTests } from "@/types/validate";

interface ValidateAutocorrelationTestsProps {
  data: AutocorrelationTests;
  analysisId: string;
  isDynamic: boolean;
}

export function ValidateAutocorrelationTests({
  data,
  analysisId,
  isDynamic,
}: ValidateAutocorrelationTestsProps) {
  return (
    <PlotGroup
      title="Autocorrelation Tests"
      description={data.description}
      files={data.files}
      analysisId={analysisId}
      isDynamic={isDynamic}
      showFunctionInfo={true}
    />
  );
} 