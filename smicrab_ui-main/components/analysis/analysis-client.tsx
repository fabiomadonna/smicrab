"use client";

import { useState, useEffect } from "react";
import { Analysis, AnalyzeStatus } from "@/types";
import { getAnalysisStatusAction } from "@/actions";
import { AnalysisLayout } from "./analysis-layout";
import { AnalysisConfigurationClient } from "./analysis-configuration-client";
import { AnalysisConfigured } from "./analysis-configured";
import { AnalysisInProgress } from "./analysis-in-progress";
import { AnalysisSummary } from "./analysis-summary";
import { AnalysisError } from "./analysis-error";

interface AnalysisClientProps {
  analysisId: string;
  initialAnalysis: Analysis;
}

export function AnalysisClient({
  analysisId,
  initialAnalysis,
}: AnalysisClientProps) {
  const [analysis, setAnalysis] = useState<Analysis>(initialAnalysis);
  const [isPolling, setIsPolling] = useState(false);

  // Status polling every 5 seconds
  useEffect(() => {
    if (
      analysis.status === AnalyzeStatus.COMPLETED ||
      analysis.status === AnalyzeStatus.ERROR
    ) {
      return;
    }

    const pollStatus = async () => {
      setIsPolling(true);
      try {
        const response = await getAnalysisStatusAction(analysisId);

        if (response.success && response.data) {
          setAnalysis(response.data);
        } else {
          console.error("Failed to get analysis status:", response.error);
        }
      } catch (error) {
        console.error("Error polling analysis status:", error);
      } finally {
        setIsPolling(false);
      }
    };

    // Poll immediately and then every 5 seconds
    pollStatus();
    const interval = setInterval(pollStatus, 5000);

    return () => clearInterval(interval);
  }, [analysisId, analysis.status]);

  const handleRetry = () => {
    // Force refresh the analysis status after retry
    const refreshStatus = async () => {
      const response = await getAnalysisStatusAction(analysisId);
      if (response.success && response.data) {
        setAnalysis(response.data);
      }
    };
    refreshStatus();
  };

  const handleReconfigure = () => {
    // Reset status to pending to show configuration form
    setAnalysis({ ...analysis, status: AnalyzeStatus.PENDING });
  };

  const renderContent = () => {
    switch (analysis.status) {
      case AnalyzeStatus.PENDING:
        return (
          <div className="max-w-5xl mx-auto">
            <AnalysisConfigurationClient
              analysisId={analysisId}
              analysis={analysis}
            />
          </div>
        );

      case AnalyzeStatus.CONFIGURED:
        return (
          <div className="max-w-5xl mx-auto">
            <AnalysisConfigured analysis={analysis} />
          </div>
        );

      case AnalyzeStatus.IN_PROGRESS:
        return (
          <div className="max-w-5xl mx-auto">
            <AnalysisInProgress analysis={analysis} />
          </div>
        );

      case AnalyzeStatus.COMPLETED:
        return <AnalysisSummary analysis={analysis} />;

      case AnalyzeStatus.ERROR:
        return (
          <div className="max-w-5xl mx-auto">
            <AnalysisError
              analysis={analysis}
              onRetry={handleRetry}
              onReconfigure={handleReconfigure}
            />
          </div>
        );

      default:
        return (
          <div className="max-w-5xl mx-auto">
            <div className="text-center py-8">
              <p className="text-muted-foreground">
                Unknown status: {analysis.status}
              </p>
            </div>
          </div>
        );
    }
  };

  return renderContent();
}
