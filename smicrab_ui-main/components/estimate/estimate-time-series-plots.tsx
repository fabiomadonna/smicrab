"use client";

import { TimeSeriesPlots } from "@/types/estimate";
import { PlotGroup } from "@/components/ui/plot-group";

interface EstimateTimeSeriesPlotsProps {
  data: TimeSeriesPlots;
  analysisId: string;
  isDynamic: boolean;
}

export function EstimateTimeSeriesPlots({
  data,
  analysisId,
  isDynamic,
}: EstimateTimeSeriesPlotsProps) {
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