"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  CheckCircle2,
  Download,
  FileText,
  BarChart3,
  Map,
  Database,
  Calendar,
  MapPin,
  Settings2,
  CheckCircle,
  Loader2,
  Settings,
  Clock,
  Target,
  Shield,
  Activity,
} from "lucide-react";
import { Analysis, AnalyzeStatus, AnalysisVariable } from "@/types";
import { AnalysisLayout } from "./analysis-layout";
import { getVariableDisplayName } from "@/lib/utils";

interface AnalysisSummaryProps {
  analysis: Analysis;
}

export function AnalysisSummary({ analysis }: AnalysisSummaryProps) {
  const getStatusText = (status: AnalyzeStatus) => {
    switch (status) {
      case AnalyzeStatus.COMPLETED:
        return "Completed";
      case AnalyzeStatus.IN_PROGRESS:
        return "In Progress";
      case AnalyzeStatus.ERROR:
        return "Error";
      case AnalyzeStatus.PENDING:
        return "Pending Configuration";
      default:
        return "Unknown";
    }
  };

  return (
    <AnalysisLayout analysis={analysis} isPolling={false}>
      <div className="space-y-6">
        {/* Analysis Configuration Summary */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5" />
              Analysis Configuration
            </CardTitle>
            <CardDescription>
              Overview of your analysis setup and parameters
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Model Information */}
              <div className="space-y-4">
                <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                  Model Information
                </h4>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">
                      Analysis ID:
                    </span>
                    <span className="text-sm font-medium">{analysis.id}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">
                      Model Type:
                    </span>
                    <Badge variant="secondary">
                      {analysis.model_type || "Unknown"}
                    </Badge>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">
                      Analysis Date:
                    </span>
                    <span className="text-sm font-medium">
                      {analysis.analysis_date
                        ? new Date(analysis.analysis_date).toLocaleDateString()
                        : "Not specified"}
                    </span>
                  </div>

                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">
                      Analysis Status:
                    </span>
                    <Badge variant="default">
                      {getStatusText(analysis.status)}
                    </Badge>
                  </div>
                </div>
              </div>

              {/* Spatial Configuration */}
              {analysis.coordinates && (
                <div className="space-y-4">
                  <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                    Spatial Configuration
                  </h4>
                  <div className="space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Dynamic Output:
                      </span>
                      <Badge variant="secondary">
                        {analysis.is_dynamic_output ? "Enabled" : "Disabled"}
                      </Badge>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Trend:
                      </span>
                      <span className="text-sm font-medium">
                        {analysis.model_config_data?.bool_trend
                          ? "Enabled"
                          : "Disabled"}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Latitude:
                      </span>
                      <span className="text-sm font-medium">
                        {analysis.coordinates.latitude?.toFixed(4)}°N
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Longitude:
                      </span>
                      <span className="text-sm font-medium">
                        {analysis.coordinates.longitude?.toFixed(4)}°E
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Coefficient Choice:
                      </span>
                      <span className="text-sm font-medium">
                        {analysis.model_config_data?.user_coeff_choice ||
                          "Not specified"}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Variable Configuration */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Variable Configuration
            </CardTitle>
            <CardDescription>
              Endogenous and exogenous variables used in the analysis
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Endogenous Variable */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide mb-3">
                  Endogenous Variable
                </h4>
                <div className="pb-3 rounded-lg">
                  <div className="flex items-center gap-2">
                    <Activity className="w-4 h-4 text-green-600 dark:text-green-400" />
                    <span className="font-medium text-green-800 dark:text-green-400">
                      {getVariableDisplayName(
                        analysis.model_config_data
                          ?.endogenous_variable as AnalysisVariable
                      ) || "Not specified"}
                    </span>
                  </div>
                  <p className="text-xs text-green-400 dark:text-green-600 mt-1">
                    The dependent variable being predicted by the model
                  </p>
                </div>
              </div>

              {/* Exogenous Variables */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                  Exogenous Variables
                </h4>
                <p className="text-xs text-muted-foreground mb-2">
                  Independent variables used as predictors in the model
                </p>
                {analysis.model_config_data?.covariate_variables &&
                analysis.model_config_data.covariate_variables.length > 0 ? (
                  <div className="flex gap-2">
                    {analysis.model_config_data.covariate_variables.map(
                      (variable: string, index: number) => (
                        <div key={index} className="rounded-lg">
                          <div className="flex items-center gap-1">
                            <span className="font-medium text-blue-800 dark:text-blue-400">
                              {getVariableDisplayName(
                                variable as AnalysisVariable
                              )}
                            </span>
                            {index <
                              analysis?.model_config_data?.covariate_variables
                                .length -
                                1 && (
                              <span className="text-muted-foreground">, </span>
                            )}
                          </div>
                        </div>
                      )
                    )}
                  </div>
                ) : (
                  <div className="p-3 bg-muted rounded-lg">
                    <p className="text-sm text-muted-foreground">
                      No exogenous variables specified
                    </p>
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </AnalysisLayout>
  );
}
