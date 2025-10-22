"use client";

import { CsvDownloads } from "@/types/estimate";
import { PlotGroup } from "@/components/ui/plot-group";

interface EstimateCsvDownloadsProps {
  data: CsvDownloads;
  analysisId: string;
}

export function EstimateCsvDownloads({
  data,
  analysisId,
}: EstimateCsvDownloadsProps) {
  return (
    <PlotGroup
      description={data.description}
      files={data.files}
      analysisId={analysisId}
      isDynamic={false} // CSV downloads are always static
      showFunctionInfo={true}
    />
  );
} 