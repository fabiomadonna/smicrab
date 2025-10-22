"use client";

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { 
  Database, 
  Settings,
  CheckCircle,
  Download,
  BarChart3,
  ArrowRight,
  ArrowLeft,
  Play,
  FileText,
  LineChart,
  TrendingUp,
  Loader2,
  RefreshCw,
  Home,
  Activity,
  Calculator,
  Target
} from "lucide-react";

interface EstimateWizardProps {
  inputData?: any; // df_data from Input Module
  onComplete: (estimatedData: any) => void;
  onReturn?: () => void;
}

type EstimateStep = 1 | 2 | 3 | 4;

interface DatasetPreview {
  columns: string[];
  rows: any[][];
  totalRows: number;
  stats?: {
    mean?: number;
    std?: number;
    min?: number;
    max?: number;
  };
}

export function EstimateWizard({ inputData, onComplete, onReturn }: EstimateWizardProps) {
  const [currentStep, setCurrentStep] = useState<EstimateStep>(1);
  const [isEstimating, setIsEstimating] = useState(false);
  const [estimationProgress, setEstimationProgress] = useState(0);
  const [estimatedData, setEstimatedData] = useState<DatasetPreview | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const [isPlotting, setIsPlotting] = useState(false);
  const [downloadComplete, setDownloadComplete] = useState(false);
  const [plotComplete, setPlotComplete] = useState(false);

  // Sample input data preview (df_data)
  const inputDataPreview: DatasetPreview = {
    columns: ["Date", "Mean Air Temperature", "Relative Humidity", "Total Precipitation"],
    rows: [
      ["2024-01-01", "15.2", "85.4", "1.2"],
      ["2024-01-02", "16.8", "78.9", "0.8"],
      ["2024-01-03", "14.5", "92.1", "2.4"],
      ["2024-01-04", "17.2", "82.3", "0.3"],
      ["2024-01-05", "18.1", "75.6", "0.0"]
    ],
    totalRows: 150
  };

  const steps = [
    { number: 1, title: "Start", description: "Review input dataset" },
    { number: 2, title: "Estimate", description: "SPDP estimation process" },
    { number: 3, title: "Actions", description: "Download or plot results" },
    { number: 4, title: "Continue", description: "Proceed to validation" }
  ];

  const currentStepInfo = steps[currentStep - 1];
  const progressPercentage = ((currentStep - 1) / (steps.length - 1)) * 100;

  const handleNext = () => {
    if (currentStep < 4) {
      setCurrentStep((prev) => (prev + 1) as EstimateStep);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as EstimateStep);
    }
  };

  const startEstimation = async () => {
    // First move to step 2
    handleNext();
    
    // Small delay to allow UI to update
    await new Promise(resolve => setTimeout(resolve, 100));
    
    setIsEstimating(true);
    setEstimationProgress(0);

    // Simulate SPDP estimation process
    const estimationSteps = [
      "Initializing SPDP model...",
      "Processing spatial dependencies...",
      "Computing temporal dynamics...",
      "Calculating panel data effects...",
      "Estimating coefficients...",
      "Finalizing results..."
    ];

    for (let i = 0; i < estimationSteps.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      setEstimationProgress(((i + 1) / estimationSteps.length) * 100);
    }

    // Generate sample estimated data (df_estimate)
    const estimated: DatasetPreview = {
      columns: ["Date", "Estimated_Temperature", "Spatial_Effect", "Temporal_Effect", "Residual"],
      rows: [
        ["2024-01-01", "15.18", "0.12", "-0.05", "0.07"],
        ["2024-01-02", "16.75", "0.08", "0.02", "0.03"],
        ["2024-01-03", "14.52", "-0.15", "0.08", "-0.05"],
        ["2024-01-04", "17.15", "0.04", "-0.02", "0.03"],
        ["2024-01-05", "18.08", "0.06", "0.01", "0.01"]
      ],
      totalRows: 150,
      stats: {
        mean: 16.34,
        std: 1.45,
        min: 12.8,
        max: 19.7
      }
    };

    setEstimatedData(estimated);
    setIsEstimating(false);
    // Don't automatically move to next step - let user manually navigate
  };

  const handleDownload = async () => {
    setIsDownloading(true);
    // Simulate download
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsDownloading(false);
    setDownloadComplete(true);
    
    // Here you would trigger actual file download
    console.log("Estimated dataset downloaded", estimatedData);
  };

  const handlePlot = async () => {
    setIsPlotting(true);
    // Simulate plot generation
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsPlotting(false);
    setPlotComplete(true);
    
    // Here you would open plot interface
    console.log("Plot generated for estimated data", estimatedData);
  };

  const handleContinueToValidate = () => {
    if (estimatedData) {
      onComplete(estimatedData);
    }
  };

  const canProceedFromStep = (step: EstimateStep): boolean => {
    switch (step) {
      case 1: return true;
      case 2: return estimatedData !== null;
      case 3: return true;
      case 4: return true;
      default: return false;
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="h-6 w-6 text-primary" />
                Input Data Preview
              </CardTitle>
              <CardDescription>
                Review the dataset from the Input Module before starting SPDP estimation
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {inputDataPreview && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="text-lg font-semibold">Dataset Overview (df_data)</h3>
                    <Badge variant="secondary">
                      {inputDataPreview.totalRows} rows
                    </Badge>
                  </div>
                  
                  <div className="border rounded-lg overflow-hidden">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          {inputDataPreview.columns.map((column, index) => (
                            <TableHead key={index}>{column}</TableHead>
                          ))}
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {inputDataPreview.rows.map((row, index) => (
                          <TableRow key={index}>
                            {row.map((cell, cellIndex) => (
                              <TableCell key={cellIndex}>{cell}</TableCell>
                            ))}
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                  
                  <p className="text-sm text-muted-foreground text-center">
                    Showing first 5 rows of {inputDataPreview.totalRows} total rows from Input Module
                  </p>
                </div>
              )}

              {/* Start Estimation */}
              <div className="text-center space-y-4 pt-6">
                <div className="p-6 bg-primary/10 rounded-lg border border-primary/20">
                  <TrendingUp className="h-12 w-12 text-primary mx-auto mb-4" />
                  <h3 className="font-semibold mb-2">Ready to Start SPDP Estimation</h3>
                  <p className="text-sm text-muted-foreground mb-4">
                    This will process your dataset using Spatial Dynamic Panel Data methodology
                    to estimate spatial-temporal relationships and generate df_estimate.
                  </p>
                  <Button onClick={startEstimation} size="lg" className="px-8">
                    <Play className="mr-2 h-5 w-5" />
                    Start Estimation
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        );

      case 2:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calculator className="h-6 w-6 text-primary" />
                SPDP Estimation Process
              </CardTitle>
              <CardDescription>
                Processing your data with Spatial Dynamic Panel Data methodology
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {isEstimating && (
                <div className="text-center space-y-6">
                  <div className="p-8">
                    <Loader2 className="h-16 w-16 text-primary mx-auto mb-6 animate-spin" />
                    <h3 className="text-xl font-semibold mb-4">Estimating SPDP... Please wait.</h3>
                    <div className="space-y-3">
                      <div className="flex justify-between text-sm max-w-md mx-auto">
                        <span>Processing spatial-temporal relationships</span>
                        <span>{Math.round(estimationProgress)}%</span>
                      </div>
                      <Progress value={estimationProgress} className="w-full max-w-md mx-auto h-3" />
                    </div>
                    <p className="text-sm text-muted-foreground mt-4">
                      This process analyzes spatial dependencies and temporal dynamics in your data
                    </p>
                  </div>
                </div>
              )}

              {estimatedData && !isEstimating && (
                <div className="space-y-6">
                  {/* Success Message */}
                  <div className="p-4 bg-green-500/10 rounded-lg border border-green-500/20">
                    <div className="flex items-center gap-2 mb-2">
                      <CheckCircle className="h-5 w-5 text-green-500 dark:text-green-300" />
                      <span className="font-medium text-green-700 dark:text-green-300">
                        SPDP Estimation Complete!
                      </span>
                    </div>
                    <p className="text-sm text-green-500 dark:text-green-300">
                      Your dataset has been successfully processed using Spatial Dynamic Panel Data methodology.
                    </p>
                  </div>

                  {/* Estimation Statistics */}
                  {estimatedData.stats && (
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <Card>
                        <CardContent className="p-4 text-center">
                          <p className="text-2xl font-bold text-primary">{estimatedData.stats.mean?.toFixed(2)}</p>
                          <p className="text-sm text-muted-foreground">Mean</p>
                        </CardContent>
                      </Card>
                      <Card>
                        <CardContent className="p-4 text-center">
                          <p className="text-2xl font-bold text-green-500 dark:text-green-300">{estimatedData.stats.std?.toFixed(2)}</p>
                          <p className="text-sm text-muted-foreground">Std Dev</p>
                        </CardContent>
                      </Card>
                      <Card>
                        <CardContent className="p-4 text-center">
                          <p className="text-2xl font-bold text-amber-500 dark:text-amber-300">{estimatedData.stats.min?.toFixed(2)}</p>
                          <p className="text-sm text-muted-foreground">Min</p>
                        </CardContent>
                      </Card>
                      <Card>
                        <CardContent className="p-4 text-center">
                          <p className="text-2xl font-bold text-red-500 dark:text-red-300">{estimatedData.stats.max?.toFixed(2)}</p>
                          <p className="text-sm text-muted-foreground">Max</p>
                        </CardContent>
                      </Card>
                    </div>
                  )}

                  {/* Estimated Data Preview */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-semibold">Estimated Dataset Preview (df_estimate)</h3>
                      <Badge variant="secondary">
                        {estimatedData.totalRows} rows estimated
                      </Badge>
                    </div>
                    
                    <div className="border rounded-lg overflow-hidden">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            {estimatedData.columns.map((column, index) => (
                              <TableHead key={index}>{column}</TableHead>
                            ))}
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {estimatedData.rows.map((row, index) => (
                            <TableRow key={index}>
                              {row.map((cell, cellIndex) => (
                                <TableCell key={cellIndex}>{cell}</TableCell>
                              ))}
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                    
                    <p className="text-sm text-muted-foreground text-center">
                      Showing first 5 rows of {estimatedData.totalRows} estimated results
                    </p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        );

      case 3:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-6 w-6 text-primary" />
                Estimated Data Actions
              </CardTitle>
              <CardDescription>
                Download or visualize your SPDP estimation results
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Download Option */}
                <Card className={`border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer ${downloadComplete ? 'bg-primary/5' : ''}`}>
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                      {downloadComplete ? (
                        <CheckCircle className="h-8 w-8 text-green-500 dark:text-green-300" />
                      ) : (
                        <Download className="h-8 w-8 text-primary" />
                      )}
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Download Estimated Data</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Save your SPDP estimation results as CSV (DF2) for external analysis
                      </p>
                    </div>
                    <Button 
                      onClick={handleDownload} 
                      disabled={isDownloading}
                      className="w-full"
                      size="lg"
                      variant={downloadComplete ? "outline" : "default"}
                    >
                      {isDownloading ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Downloading...
                        </>
                      ) : downloadComplete ? (
                        <>
                          <CheckCircle className="mr-2 h-4 w-4" />
                          Downloaded
                        </>
                      ) : (
                        <>
                          <Download className="mr-2 h-4 w-4" />
                          Download CSV
                        </>
                      )}
                    </Button>
                  </CardContent>
                </Card>

                {/* Plot Option */}
                <Card className={`border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer ${plotComplete ? 'bg-primary/5' : ''}`}>
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                      {plotComplete ? (
                        <CheckCircle className="h-8 w-8 text-green-500 dark:text-green-300" />
                      ) : (
                        <LineChart className="h-8 w-8 text-primary" />
                      )}
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Generate Plots</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Create visualizations to analyze estimation results and spatial patterns
                      </p>
                    </div>
                    <Button 
                      onClick={handlePlot} 
                      disabled={isPlotting}
                      className="w-full"
                      size="lg"
                      variant={plotComplete ? "outline" : "default"}
                    >
                      {isPlotting ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Generating...
                        </>
                      ) : plotComplete ? (
                        <>
                          <CheckCircle className="mr-2 h-4 w-4" />
                          Generated
                        </>
                      ) : (
                        <>
                          <LineChart className="mr-2 h-4 w-4" />
                          Generate Plots
                        </>
                      )}
                    </Button>
                  </CardContent>
                </Card>
              </div>

              {/* Action Status */}
              <div className="text-center p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                <p className="text-sm text-muted-foreground">
                  💡 You can use both options in any order - download for offline analysis or plot for immediate insights
                </p>
                {(downloadComplete || plotComplete) && (
                  <div className="mt-2 flex items-center justify-center gap-4 text-sm">
                    {downloadComplete && (
                      <span className="flex items-center gap-1 text-green-500 dark:text-green-300">
                        <CheckCircle className="h-4 w-4" />
                        Download complete
                      </span>
                    )}
                    {plotComplete && (
                      <span className="flex items-center gap-1 text-green-500 dark:text-green-300">
                        <CheckCircle className="h-4 w-4" />
                        Plot created
                      </span>
                    )}
                  </div>
                )}
              </div>

              {/* Dataset Preview Table */}
              {estimatedData && (
                <div className="space-y-4">
                  <Separator />
                  <h4 className="font-medium">Dataset Preview</h4>
                  <div className="border rounded-lg overflow-hidden max-h-64 overflow-y-auto">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          {estimatedData.columns.map((column, index) => (
                            <TableHead key={index} className="sticky top-0 bg-background">{column}</TableHead>
                          ))}
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {estimatedData.rows.map((row, index) => (
                          <TableRow key={index}>
                            {row.map((cell, cellIndex) => (
                              <TableCell key={cellIndex}>{cell}</TableCell>
                            ))}
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        );

      case 4:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="h-6 w-6 text-green-500 dark:text-green-300" />
                Estimation Module Complete
              </CardTitle>
              <CardDescription>
                Your SPDP estimation is ready for validation
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Success Message */}
              <div className="p-4 bg-green-500/10 dark:bg-green-900/20 rounded-lg border border-green-500/20">
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle className="h-5 w-5 text-green-500 dark:text-green-300" />
                  <span className="font-medium text-green-700 dark:text-green-300">
                    SPDP Estimation Successfully Completed!
                  </span>
                </div>
                <p className="text-sm text-green-500 dark:text-green-300">
                  Your spatial-temporal dataset (DF2) has been generated using advanced SPDP methodology
                  and is ready for the validation phase.
                </p>
              </div>

              {/* Summary Stats */}
              {estimatedData?.stats && (
                <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                  <h3 className="font-medium text-primary mb-2">
                    Estimation Summary
                  </h3>
                  <div className="text-sm text-primary/80 space-y-1">
                    <p>Processed: {estimatedData.totalRows} spatial-temporal observations</p>
                    <p>Variables: {estimatedData.columns.length} estimated parameters</p>
                    <p>Method: Spatial Dynamic Panel Data (SPDP) estimation</p>
                  </div>
                </div>
              )}

              <div className="text-center">
                <Button onClick={handleContinueToValidate} size="lg" className="px-8">
                  Continue to Validation Module
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </div>
            </CardContent>
          </Card>
        );

      default:
        return null;
    }
  };

  return (
    <div className="space-y-8">
      {/* Progress Header */}
      <div className="max-w-4xl mx-auto">
        <div className="text-center space-y-4 mb-8">
          <div className="flex items-center justify-center space-x-4">
            <Badge variant="outline" className="text-sm">
              Step {currentStep} of {steps.length}
            </Badge>
            <Badge variant="secondary">
              {currentStepInfo.title}
            </Badge>
          </div>
          
          <div className="space-y-2">
            <h2 className="text-xl font-semibold">{currentStepInfo.description}</h2>
            <div className="w-full max-w-md mx-auto">
              <Progress value={progressPercentage} className="h-2" />
            </div>
          </div>
        </div>

        {/* Step Navigation */}
        <div className="flex justify-center mb-8">
          <div className="flex items-center space-x-2">
            {steps.map((step, index) => (
              <div key={step.number} className="flex items-center">
                <div className={`
                  w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium
                  ${step.number === currentStep
                    ? 'bg-purple-500 text-white'
                    : step.number < currentStep
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-300'
                  }
                `}>
                  {step.number < currentStep ? (
                    <CheckCircle className="h-4 w-4" />
                  ) : (
                    step.number
                  )}
                </div>
                {index < steps.length - 1 && (
                  <div className={`w-8 h-0.5 mx-2 ${
                    step.number < currentStep ? 'bg-green-500' : 'bg-gray-200 dark:bg-gray-700'
                  }`} />
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Step Content */}
      <div className="min-h-[500px]">
        {renderStepContent()}
      </div>

      {/* Navigation Buttons */}
      {currentStep > 1 && currentStep < 4 && (
        <div className="max-w-4xl mx-auto flex justify-between items-center pt-6 border-t">
          <Button
            onClick={handlePrevious}
            variant="outline"
            disabled={currentStep === 1 || isEstimating}
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Previous
          </Button>
          
          <Button
            onClick={handleNext}
            disabled={!canProceedFromStep(currentStep) || isEstimating}
          >
            Next
            <ArrowRight className="ml-2 h-4 w-4" />
          </Button>
        </div>
      )}
    </div>
  );
} 