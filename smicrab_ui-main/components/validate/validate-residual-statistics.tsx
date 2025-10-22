"use client";

import { PlotGroup } from "@/components/ui/plot-group";
import { ResidualSummaryStatistics } from "@/types/validate";

interface ValidateResidualStatisticsProps {
  data: ResidualSummaryStatistics;
  analysisId: string;
  isDynamic: boolean;
}

export function ValidateResidualStatistics({
  data,
  analysisId,
  isDynamic,
}: ValidateResidualStatisticsProps) {
  return (
    <PlotGroup
      title="Residual Summary Statistics"
      description={data.description}
      files={data.files}
      analysisId={analysisId}
      isDynamic={isDynamic}
      showFunctionInfo={true}
    />
  );
} 