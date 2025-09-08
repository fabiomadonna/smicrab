"use client";

import { DescribeModulePlotGroup } from "@/types/describe";
import { PlotGroup } from "@/components/ui/plot-group";
import { getVariableDisplayName } from "@/lib/utils";

interface DescribePlotGroupProps {
  plotGroup: DescribeModulePlotGroup;
  analysisId: string;
  isDynamic: boolean;
}

export function DescribePlotGroup({ plotGroup, analysisId, isDynamic }: DescribePlotGroupProps) {
  // Convert describe files to the common PlotFile format
  const convertedFiles = plotGroup.files.map(file => ({
    name: file.name,
    variable: file.variable,
    path_dynamic: file.path_dynamic,
    path_static: file.path_static,
    function: file.function,
    description: file.description || (file.variable ? `Variable: ${file.variable}` : file.name)
  }));

  return (
    <PlotGroup
      description={plotGroup.description}
      files={convertedFiles}
      analysisId={analysisId}
      isDynamic={isDynamic}
      getDisplayName={(name) => {
        const file = convertedFiles.find(f => f.name === name);
        return file?.variable ? getVariableDisplayName(file.variable as any) : name;
      }}
      showFunctionInfo={true}
    />
  );
} 