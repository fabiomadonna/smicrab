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
  AlertCircle,
  RefreshCw,
  Settings,
  FileText,
  Clock,
  HelpCircle,
} from "lucide-react";
import { Analysis } from "@/types";
import { runAnalysisAction } from "@/actions";
import { toast } from "sonner";
import Link from "next/link";

interface AnalysisErrorProps {
  analysis: Analysis;
  onRetry?: () => void;
  onReconfigure?: () => void;
}

export function AnalysisError({
  analysis,
  onRetry,
  onReconfigure,
}: AnalysisErrorProps) {
  const handleRetry = async () => {
    if (analysis.model_type) {
      try {
        toast.info("Retrying analysis...");
        const result = await runAnalysisAction({
          analysis_id: analysis.id,
        });

        if (result.success) {
          toast.success("Analysis restarted successfully");
          if (onRetry) onRetry();
        } else {
          toast.error("Failed to restart analysis: " + result.error);
        }
      } catch (error) {
        toast.error("Failed to restart analysis");
        console.error("Retry error:", error);
      }
    } else {
      toast.error("Cannot retry: Analysis not properly configured");
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const commonErrors = [
    {
      pattern: /timeout/i,
      title: "Analysis Timeout",
      description: "The analysis took too long to complete and was terminated.",
      suggestions: [
        "Try reducing the complexity of your model",
        "Consider using a simpler model type",
        "Check if your data range is too large",
      ],
    },
    {
      pattern: /memory|out of memory/i,
      title: "Memory Error",
      description:
        "The analysis ran out of available memory during processing.",
      suggestions: [
        "Try reducing the spatial or temporal extent",
        "Use fewer covariate variables",
        "Consider processing smaller data chunks",
      ],
    },
    {
      pattern: /data|missing|invalid/i,
      title: "Data Error",
      description: "There was an issue with the input data or parameters.",
      suggestions: [
        "Check your coordinate values are within valid ranges",
        "Verify the selected date is within the available data range",
        "Ensure all required parameters are properly configured",
      ],
    },
    {
      pattern: /model|convergence/i,
      title: "Model Error",
      description:
        "The statistical model failed to converge or encountered an error.",
      suggestions: [
        "Try a different model type",
        "Adjust the coefficient choice parameter",
        "Check if the selected variables are appropriate for the model",
      ],
    },
  ];

  const getErrorInfo = (errorMessage: string) => {
    if (!errorMessage) return null;

    const matchedError = commonErrors.find((error) =>
      error.pattern.test(errorMessage)
    );

    return (
      matchedError || {
        title: "Unknown Error",
        description: "An unexpected error occurred during analysis.",
        suggestions: [
          "Try running the analysis again",
          "Check your configuration parameters",
          "Contact support if the problem persists",
        ],
      }
    );
  };

  const errorInfo = getErrorInfo(analysis.error_message || "");

  return (
    <div className="space-y-6 pt-20 pb-14">
      {/* Error Header */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-red-100 rounded-full">
              <AlertCircle className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
            <div>
              <CardTitle className="flex items-center gap-2">
                Analysis Failed
                <Badge
                  variant="outline"
                  className="bg-red-100 text-red-800 border-red-200 dark:bg-red-900 dark:text-red-200 dark:border-red-800"
                >
                  Error
                </Badge>
              </CardTitle>
              <CardDescription>
                Your analysis encountered an error and could not be completed.
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            {/* <Button
              onClick={handleRetry}
              variant="outline"
              className="border-red-300 text-red-700 hover:bg-red-50  dark:text-red-300"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Retry Analysis
            </Button>
            {onReconfigure && (
              <Button
                onClick={onReconfigure}
                variant="outline"
                className="border-red-300 text-red-700 hover:bg-red-50  dark:text-red-300"
              >
                <Settings className="w-4 h-4 mr-2" />
                Reconfigure
              </Button>
            )} */}
            <div className="text-sm text-muted-foreground">
              <Clock className="w-4 h-4 inline mr-1" />
              Failed on {formatDate(analysis.updated_at)}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Error Details */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            Analysis Log
          </CardTitle>
          <CardDescription className="mt-4">
            <div className="flex items-center gap-1">
              Go to
              <Link
                about="Logs"
                className="text-blue-500 hover:text-blue-600 dark:text-blue-400 font-semibold"
                target="_blank"
                href={`/tmp/analysis/${analysis.id}/${analysis.model_type}/analysis_log.log`}
              >
                analysis_log.log
              </Link>
              to see the all logs
            </div>
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {errorInfo && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg dark:bg-red-950 dark:text-red-200">
                <h4 className="font-medium text-red-900 mb-2">
                  {errorInfo.title}
                </h4>
                <p className="text-sm text-red-700 mb-3 dark:text-red-300">
                  {errorInfo.description}
                </p>
                <div className="space-y-2">
                  <h5 className="font-medium text-red-900 text-sm">
                    Suggested Solutions:
                  </h5>
                  <ul className="text-sm text-red-700 space-y-1 dark:text-red-300">
                    {errorInfo.suggestions.map((suggestion, index) => (
                      <li key={index} className="flex items-start gap-2">
                        <span className="text-red-500 mt-1">•</span>
                        {suggestion}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}

            {analysis.error_message && (
              <div className="p-4 bg-gray-50 border rounded-lg">
                <h4 className="font-medium text-gray-900 mb-2">
                  Technical Error Message
                </h4>
                <code className="text-sm text-gray-700 bg-gray-100 p-2 rounded block">
                  {analysis.error_message}
                </code>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Analysis Configuration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="w-5 h-5" />
            Analysis Configuration
          </CardTitle>
          <CardDescription>
            The configuration that was used when the error occurred
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-3 bg-muted rounded-lg">
              <div className="text-sm font-medium text-muted-foreground">
                Model Type
              </div>
              <div className="font-semibold">
                {analysis.model_type || "N/A"}
              </div>
            </div>
            {analysis.coordinates && (
              <div className="p-3 bg-muted rounded-lg">
                <div className="text-sm font-medium text-muted-foreground">
                  Location
                </div>
                <div className="font-semibold">
                  {analysis.coordinates.latitude?.toFixed(2)}°N,{" "}
                  {analysis.coordinates.longitude?.toFixed(2)}°E
                </div>
              </div>
            )}
            <div className="p-3 bg-muted rounded-lg">
              <div className="text-sm font-medium text-muted-foreground">
                Dynamic Output
              </div>
              <div className="font-semibold">
                {analysis.is_dynamic_output ? "Enabled" : "Disabled"}
              </div>
            </div>
            <div className="p-3 bg-muted rounded-lg">
              <div className="text-sm font-medium text-muted-foreground">
                Analysis Date
              </div>
              <div className="font-semibold">
                {analysis.analysis_date
                  ? new Date(analysis.analysis_date).toLocaleDateString()
                  : "N/A"}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Troubleshooting Guide */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HelpCircle className="w-5 h-5" />
            Troubleshooting Guide
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 text-sm">
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Check Parameters:</span> Verify
                that all configuration parameters are within valid ranges and
                properly formatted
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Simplify Model:</span> Try using a
                simpler model type or reducing the number of variables if the
                analysis is too complex
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Data Range:</span> Ensure your
                selected coordinates and dates are within the available dataset
                coverage
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Try Again:</span> Some errors are
                temporary - try running the analysis again with the same
                parameters
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Get Help:</span> If the problem
                persists, contact technical support with the error message above
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
