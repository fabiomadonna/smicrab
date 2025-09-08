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
  Play,
  FileText,
  BarChart3,
  Settings,
  Calendar,
  MapPin,
  Activity,
  Loader2,
} from "lucide-react";
import { Analysis, AnalysisVariable } from "@/types";
import { getVariableDisplayName } from "@/lib/utils";
import { runAnalysisAction } from "@/actions";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";

interface AnalysisConfiguredProps {
  analysis: Analysis;
}

export function AnalysisConfigured({ analysis }: AnalysisConfiguredProps) {
  const [isStarting, setIsStarting] = useState(false);
  const router = useRouter();

  const handleStartAnalysis = async () => {
    setIsStarting(true);
    
    try {
      const result = await runAnalysisAction({
        analysis_id: analysis.id,
      });

      if (result.success) {
        toast.success(result.message || "Analysis started successfully!");
        // Refresh the page to show updated status
        router.refresh();
      } else {
        const errorMessage = typeof result.error === 'string' 
          ? result.error 
          : Array.isArray(result.error)
            ? result.error.map(e => `${e.field}: ${e.message}`).join(', ')
            : "Failed to start analysis";
        toast.error(errorMessage);
      }
    } catch (error) {
      console.error("Error starting analysis:", error);
      toast.error("An unexpected error occurred");
    } finally {
      setIsStarting(false);
    }
  };

  return (
      <div className="space-y-6 max-w-5xl mx-auto mt-10">
        {/* Ready to Start Header */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-green-600" />
              Analysis Ready to Start
            </CardTitle>
            <CardDescription>
              Your analysis has been configured successfully. Review the settings below and start the analysis when ready.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Badge variant="secondary" className="bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400">
                    <CheckCircle2 className="w-3 h-3 mr-1" />
                    Configured
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    All parameters have been set
                  </span>
                </div>
                <p className="text-sm text-muted-foreground">
                  Analysis ID: {analysis.id}
                </p>
              </div>
              <Button 
                onClick={handleStartAnalysis}
                disabled={isStarting}
                size="lg"
                className="bg-green-600 hover:bg-green-700 text-white"
              >
                {isStarting ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Starting...
                  </>
                ) : (
                  <>
                    <Play className="w-4 h-4 mr-2" />
                    Start Analysis
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Analysis Configuration Summary */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5" />
              Configuration Summary
            </CardTitle>
            <CardDescription>
              Review your analysis parameters before starting
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
                      Summary Statistic:
                    </span>
                    <span className="text-sm font-medium">
                      {analysis.model_config_data?.summary_stat || "Not specified"}
                    </span>
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
                        Trend Analysis:
                      </span>
                      <Badge variant="secondary">
                        {analysis.model_config_data?.bool_trend ? "Enabled" : "Disabled"}
                      </Badge>
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
              <BarChart3 className="w-5 h-5" />
              Variable Configuration
            </CardTitle>
            <CardDescription>
              Variables selected for the analysis
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Endogenous Variable */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide mb-3">
                  Endogenous Variable (Dependent)
                </h4>
                <div className="p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
                  <div className="flex items-center gap-2">
                    <Activity className="w-4 h-4 text-green-600 dark:text-green-400" />
                    <span className="font-medium text-green-800 dark:text-green-400">
                      {getVariableDisplayName(
                        analysis.model_config_data
                          ?.endogenous_variable as AnalysisVariable
                      ) || "Not specified"}
                    </span>
                  </div>
                  <p className="text-xs text-green-600 dark:text-green-500 mt-1">
                    The dependent variable being predicted by the model
                  </p>
                </div>
              </div>

              {/* Exogenous Variables */}
              <div>
                <h4 className="font-medium text-sm text-muted-foreground uppercase tracking-wide mb-3">
                  Exogenous Variables (Independent)
                </h4>
                {analysis.model_config_data?.covariate_variables &&
                analysis.model_config_data.covariate_variables.length > 0 ? (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    {analysis.model_config_data.covariate_variables.map(
                      (variable: string, index: number) => (
                        <div key={index} className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                          <div className="flex items-center gap-2">
                            <BarChart3 className="w-3 h-3 text-blue-600 dark:text-blue-400" />
                            <span className="text-sm font-medium text-blue-800 dark:text-blue-400">
                              {getVariableDisplayName(
                                variable as AnalysisVariable
                              )}
                            </span>
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

        {/* Next Steps Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5" />
              What Happens Next?
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/20 flex items-center justify-center mt-0.5">
                  <span className="text-xs font-medium text-blue-600 dark:text-blue-400">1</span>
                </div>
                <div>
                  <p className="font-medium text-sm">Data Processing</p>
                  <p className="text-sm text-muted-foreground">
                    Your data will be loaded and processed according to the selected configuration.
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/20 flex items-center justify-center mt-0.5">
                  <span className="text-xs font-medium text-blue-600 dark:text-blue-400">2</span>
                </div>
                <div>
                  <p className="font-medium text-sm">Model Estimation</p>
                  <p className="text-sm text-muted-foreground">
                    The {analysis.model_type} model will be estimated using your selected variables.
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/20 flex items-center justify-center mt-0.5">
                  <span className="text-xs font-medium text-blue-600 dark:text-blue-400">3</span>
                </div>
                <div>
                  <p className="font-medium text-sm">Validation & Results</p>
                  <p className="text-sm text-muted-foreground">
                    The model will be validated and results will be generated for download.
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
  );
} 