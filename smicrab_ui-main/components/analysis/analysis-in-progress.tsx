"use client";

import { useState, useEffect } from "react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Loader2,
  Clock,
  Activity,
  Database,
  BarChart3,
  CheckCircle2,
  MapPin,
  AlertCircle,
} from "lucide-react";
import { Analysis, ModuleName } from "@/types";

interface AnalysisInProgressProps {
  analysis: Analysis;
}

interface ProcessingStep {
  id: ModuleName;
  title: string;
  description: string;
  icon: React.ReactNode;
  status: "pending" | "in_progress" | "completed" | "error";
}

export function AnalysisInProgress({ analysis }: AnalysisInProgressProps) {
  const [elapsedTime, setElapsedTime] = useState(0);

  const processingSteps: ProcessingStep[] = [
    {
      id: ModuleName.LOAD_MODULE,
      title: "Data Module",
      description: "Loading and preparing spatial-temporal datasets",
      icon: <Database className="w-4 h-4" />,
      status: "pending",
    },
    {
      id: ModuleName.DESCRIBE_MODULE,
      title: "Describe Module",
      description: "Analyzing temporal and spatial patterns",
      icon: <BarChart3 className="w-4 h-4" />,
      status: "pending",
    },
    {
      id: ModuleName.ESTIMATE_MODULE,
      title: "Estimate Module",
      description: "Running spatial-temporal model estimation",
      icon: <Activity className="w-4 h-4" />,
      status: "pending",
    },
    {
      id: ModuleName.VALIDATE_MODULE,
      title: "Validate Module",
      description: "Validating model results and parameters",
      icon: <CheckCircle2 className="w-4 h-4" />,
      status: "pending",
    },
    {
      id: ModuleName.RISK_MAP_MODULE,
      title: "Risk Map Module",
      description: "Generating risk maps and visualizations",
      icon: <MapPin className="w-4 h-4" />,
      status: "pending",
    },
  ];

  const processingStep = processingSteps.find(
    (step) => step.id === analysis.current_module
  );
  // Determine current step based on analysis.current_module
  const currentStep = analysis.current_module
    ? processingSteps.findIndex((step) => step.id === analysis.current_module)
    : -1;

  // Update step statuses based on current step
  const updatedProcessingSteps = processingSteps.map((step, index) => ({
    ...step,
    status:
      index < currentStep
        ? "completed"
        : index === currentStep
        ? "in_progress"
        : "pending",
  }));

  const serverTimeString = analysis.updated_at;
  const startTimeUTC = new Date(serverTimeString);
  
  // Calculate elapsed time since analysis started
  useEffect(() => {
    if (analysis.status === "in_progress" && analysis.updated_at) {

      const now = new Date();
      
      const elapsedMs = now.getTime() - startTimeUTC.getTime();
      const elapsedSeconds = Math.floor(elapsedMs / 1000);

      const updateElapsedTime = () => {
        const now = new Date();
        const elapsedMs = now.getTime() - startTimeUTC.getTime();
        const elapsedSeconds = Math.floor(elapsedMs / 1000);
        setElapsedTime(elapsedSeconds);
      };

      updateElapsedTime();
      const interval = setInterval(updateElapsedTime, 1000);

      return () => clearInterval(interval);
    }
  }, [analysis.status, analysis.updated_at]);

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (hours > 0) {
      return `${hours.toString().padStart(2, "0")}:${mins
        .toString()
        .padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
    }
    if (mins > 0) {
      return `${mins.toString().padStart(2, "0")}:${secs
        .toString()
        .padStart(2, "0")}`;
    }
    return `${secs.toString().padStart(2, "0")}s`;
  };

  const getStepStatusColor = (status: ProcessingStep["status"]) => {
    switch (status) {
      case "completed":
        return "text-green-600 bg-green-50";
      case "in_progress":
        return "text-blue-600 dark:text-blue-400 bg-blue-50";
      case "error":
        return "text-red-600 bg-red-50";
      default:
        return "text-gray-500 bg-gray-50";
    }
  };

  // Calculate progress based on current module from analysis
  const progressPercentage = Math.min(
    (currentStep / updatedProcessingSteps.length) * 100,
    100
  );

  return (
    <div className="flex flex-1 items-center min-h-[calc(100vh-6rem)] justify-center max-w-3xl mx-auto space-y-6">
      {/* Main Status Card */}
      <Card className="border-none bg-transparent w-full space-y-6">
        <CardHeader>
          <div className="flex justify-center mb-8">
            <Loader2 className="w-20 h-20 animate-spin stroke-1 text-muted-foreground" />
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div>
                <CardTitle className="flex flex-col items-start gap-4">
                  Analysis in Progress
                  <Badge
                    variant="outline"
                    className="bg-blue-100 text-blue-800 border-blue-200"
                  >
                    Processing
                  </Badge>
                </CardTitle>
              </div>
            </div>

            <div className="text-right">
              <div className="text-2xl font-mono font-bold text-blue-600 dark:text-blue-400">
                {formatTime(elapsedTime)}
              </div>
              <div className="text-sm text-muted-foreground">Elapsed time</div>
            </div>
          </div>
        </CardHeader>
        <div className=" px-4 text-muted-foreground">
          Your spatial-temporal analysis is being processed. Please wait while
          we complete all modules.
        </div>
        <CardContent>
          <div className="space-y-8">
            {/* Progress Bar */}
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="font-medium">
                  Processing {processingStep?.title}...
                </span>
                <span className="text-muted-foreground">
                  {Math.round(progressPercentage)}%
                </span>
              </div>
              <Progress value={progressPercentage} className="h-2" />
            </div>

            {/* Analysis Configuration Summary */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-4">
              <div className="text-sm text-center flex flex-col gap-2">
                <span className="font-medium text-xs text-muted-foreground">
                  Model Type
                </span>
                <p className="font-medium">{analysis.model_type || "N/A"}</p>
              </div>
              {analysis.coordinates && (
                <div className="text-sm text-center flex flex-col gap-2">
                  <span className="font-medium text-xs text-muted-foreground">
                    Location
                  </span>
                  <p className="font-medium">
                    {analysis.coordinates.latitude?.toFixed(2)}°N,{" "}
                    {analysis.coordinates.longitude?.toFixed(2)}°E
                  </p>
                </div>
              )}
              <div className="text-sm text-center flex flex-col gap-2">
                <span className="font-medium text-xs text-muted-foreground">
                  Dynamic Output
                </span>
                <p className="font-medium">
                  {analysis.is_dynamic_output ? "Enabled" : "Disabled"}
                </p>
              </div>
              <div className="text-sm text-center flex flex-col gap-2">
                <span className="font-medium text-xs text-muted-foreground">
                  Status Check
                </span>
                <div className="flex items-center justify-center gap-1">
                  <p className="font-medium">Auto-refresh</p>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="w-5 h-5" />
            Processing Steps
          </CardTitle>
          <CardDescription>
            Your analysis is progressing through the following modules
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {updatedProcessingSteps.map((step, index) => (
              <div key={step.id} className="flex items-center gap-4 p-3 rounded-lg border">
                <div className={`p-2 rounded-full ${getStepStatusColor(step.status)}`}>
                  {step.icon}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium">{step.title}</h4>
                    {index === currentStep && (
                      <Badge variant="outline" className="text-xs">
                        Current
                      </Badge>
                    )}
                  </div>
                  <p className="text-sm text-muted-foreground">{step.description}</p>
                </div>
                <div className="flex items-center">
                  {getStepStatusIcon(step.status)}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="w-5 h-5" />
            Processing Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3 text-sm">
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Estimated Time:</span> Analysis typically takes 5-30 minutes depending on model complexity and data size
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Automatic Updates:</span> Status is checked every 5 seconds automatically
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Safe to Leave:</span> You can safely navigate away and return later - your analysis will continue processing
              </p>
            </div>
            <div className="flex items-start gap-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
              <p>
                <span className="font-medium">Results:</span> Once complete, you'll be able to view and download all generated plots, tables, and risk maps
              </p>
            </div>
          </div>
        </CardContent>
      </Card> */}
    </div>
  );
}
