"use client";

import { Badge } from "@/components/ui/badge";
import { Analysis } from "@/types";
import { AnalysisConfigurationForm } from "./analysis-configuration-form";

interface AnalysisConfigurationClientProps {
  analysisId: string;
  analysis: Analysis;
}

export function AnalysisConfigurationClient({
  analysisId,
  analysis,
}: AnalysisConfigurationClientProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800 border-green-200";
      case "in_progress":
        return "bg-blue-100 text-blue-800 border-blue-200";
      case "error":
        return "bg-red-100 text-red-800 border-red-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case "completed":
        return "Completed";
      case "in_progress":
        return "In Progress";
      case "error":
        return "Error";
      case "pending":
        return "Pending Configuration";
      default:
        return "Unknown";
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Analysis Configuration</h1>
          <p className="text-muted-foreground">
            Analysis ID: {analysisId.slice(-8)}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="outline" className={getStatusColor(analysis.status)}>
            {getStatusText(analysis.status)}
          </Badge>
        </div>
      </div>

      <div className="space-y-6">
        <AnalysisConfigurationForm analysisId={analysisId} />
      </div>
    </div>
  );
}
