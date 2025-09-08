"use client";

import { CoefficientTables } from "@/types/estimate";
import { PlotGroup } from "@/components/ui/plot-group";

interface EstimateCoefficientTablesProps {
  data: CoefficientTables;
  analysisId: string;
  isDynamic: boolean;
}

export function EstimateCoefficientTables({
  data,
  analysisId,
  isDynamic,
}: EstimateCoefficientTablesProps) {
  return (
    <PlotGroup
      description={data.description}
      files={data.files}
      analysisId={analysisId}
      isDynamic={isDynamic}
      showFunctionInfo={true}
    />
  );
} 