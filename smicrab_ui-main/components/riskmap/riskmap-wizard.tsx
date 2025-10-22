"use client";

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { 
  CheckCircle,
  Download,
  BarChart3,
  ArrowRight,
  ArrowLeft,
  Play,
  Globe,
  Target,
  Loader2,
  RefreshCw,
  Home,
  TrendingUp,
  AlertTriangle,
  Map,
  FileDown,
  Eye,
  Package,
  MapPin
} from "lucide-react";

interface RiskMapWizardProps {
  validatedData?: any; // df_estimate from Validate Module
  onComplete: (riskMapData: any) => void;
  onReturn?: () => void;
}

type RiskMapStep = 1 | 2 | 3 | 4 | 5 | 6;

interface ExogenousVariable {
  id: string;
  name: string;
  description: string;
  category: string;
}

interface ModelMetrics {
  rSquared: number;
  mse: number;
  rmse: number;
  mae: number;
}

interface DatasetPreview {
  columns: string[];
  rows: any[][];
  totalRows: number;
}

export function RiskMapWizard({ validatedData, onComplete, onReturn }: RiskMapWizardProps) {
  const [currentStep, setCurrentStep] = useState<RiskMapStep>(1);
  const [selectedVariables, setSelectedVariables] = useState<string[]>([]);
  const [isEstimating, setIsEstimating] = useState(false);
  const [estimationProgress, setEstimationProgress] = useState(0);
  const [modelMetrics, setModelMetrics] = useState<ModelMetrics | null>(null);
  const [modelAccepted, setModelAccepted] = useState<boolean | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const [downloadComplete, setDownloadComplete] = useState(false);
  const [isPlotting, setIsPlotting] = useState(false);
  const [plotComplete, setPlotComplete] = useState(false);
  const [showPlot, setShowPlot] = useState(false);

  // Sample validated data preview (df_estimate from Validate Module)
  const validatedDataPreview: DatasetPreview = {
    columns: ["Date", "Estimated_Temperature", "Spatial_Effect", "Temporal_Effect", "Residual"],
    rows: [
      ["2024-01-01", "15.18", "0.12", "-0.05", "0.07"],
      ["2024-01-02", "16.75", "0.08", "0.02", "0.03"],
      ["2024-01-03", "14.52", "-0.15", "0.08", "-0.05"],
      ["2024-01-04", "17.15", "0.04", "-0.02", "0.03"],
      ["2024-01-05", "18.08", "0.06", "0.01", "0.01"]
    ],
    totalRows: 150
  };

  // Sample exogenous variables
  const availableVariables: ExogenousVariable[] = [
    { id: "elevation", name: "Elevation", description: "Digital elevation model data", category: "Topographic" },
    { id: "slope", name: "Slope", description: "Terrain slope measurements", category: "Topographic" },
    { id: "aspect", name: "Aspect", description: "Terrain aspect orientation", category: "Topographic" },
    { id: "soil_type", name: "Soil Type", description: "Soil classification data", category: "Environmental" },
    { id: "land_cover", name: "Land Cover", description: "Land use and vegetation cover", category: "Environmental" },
    { id: "population", name: "Population Density", description: "Human population density", category: "Socioeconomic" },
    { id: "infrastructure", name: "Infrastructure", description: "Roads and built environment", category: "Socioeconomic" },
    { id: "water_bodies", name: "Water Bodies", description: "Lakes, rivers, and water features", category: "Environmental" }
  ];

  const groupedVariables = availableVariables.reduce((groups, variable) => {
    const group = variable.category;
    if (!groups[group]) groups[group] = [];
    groups[group].push(variable);
    return groups;
  }, {} as Record<string, ExogenousVariable[]>);

  const steps = [
    { number: 1, title: "Start", description: "Review validated dataset" },
    { number: 2, title: "Variables", description: "Select exogenous variables" },
    { number: 3, title: "Estimate", description: "Estimate global model" },
    { number: 4, title: "Validate", description: "Validate global model" },
    { number: 5, title: "Outputs", description: "Download and plot options" },
    { number: 6, title: "Complete", description: "Risk map generated" }
  ];

  const currentStepInfo = steps[currentStep - 1];
  const progressPercentage = ((currentStep - 1) / (steps.length - 1)) * 100;

  const handleNext = () => {
    if (currentStep < 6) {
      setCurrentStep((prev) => (prev + 1) as RiskMapStep);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as RiskMapStep);
    }
  };

  const handleStartVariableSelection = () => {
    setCurrentStep(2);
  };

  const handleVariableToggle = (variableId: string) => {
    setSelectedVariables(prev =>
      prev.includes(variableId)
        ? prev.filter(id => id !== variableId)
        : [...prev, variableId]
    );
  };

  const estimateGlobalModel = async () => {
    setCurrentStep(3);
    await new Promise(resolve => setTimeout(resolve, 100));
    
    setIsEstimating(true);
    setEstimationProgress(0);

    // Simulate global model estimation process
    const estimationSteps = [
      "Preparing exogenous variables...",
      "Building spatial weight matrix...",
      "Estimating global model parameters...",
      "Computing spatial autocorrelation...",
      "Generating risk predictions...",
      "Finalizing global model..."
    ];

    for (let i = 0; i < estimationSteps.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      setEstimationProgress(((i + 1) / estimationSteps.length) * 100);
    }

    // Generate model metrics
    const metrics: ModelMetrics = {
      rSquared: 0.72 + Math.random() * 0.23, // Random between 0.72-0.95
      mse: Math.random() * 0.1 + 0.05, // Random between 0.05-0.15
      rmse: 0,
      mae: 0
    };
    metrics.rmse = Math.sqrt(metrics.mse);
    metrics.mae = metrics.mse * 0.8;

    setModelMetrics(metrics);
    setIsEstimating(false);
    
    // Wait a moment to show completion, then proceed to next step
    await new Promise(resolve => setTimeout(resolve, 1500));
    setCurrentStep(4);
  };

  const handleAcceptModel = () => {
    setModelAccepted(true);
    setCurrentStep(5);
  };

  const handleRejectModel = () => {
    setModelAccepted(false);
    setCurrentStep(2);
    setModelMetrics(null);
  };

  const handleDownloadRiskMap = async () => {
    setIsDownloading(true);
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsDownloading(false);
    setDownloadComplete(true);
    
    // Toast notification would be here
    console.log("DF4 downloaded successfully");
  };

  const handlePlotRiskMap = async () => {
    setIsPlotting(true);
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsPlotting(false);
    setPlotComplete(true);
    setShowPlot(true);
  };

  const handleExportAll = async () => {
    if (!downloadComplete) {
      await handleDownloadRiskMap();
    }
    if (!plotComplete) {
      await handlePlotRiskMap();
    }
  };

  const handleProceedToNext = () => {
    setCurrentStep(6);
  };

  const handleCompleteModule = () => {
    if (modelMetrics) {
      onComplete({
        ...validatedDataPreview,
        selectedVariables: selectedVariables,
        modelMetrics: modelMetrics,
        downloadComplete: downloadComplete,
        plotComplete: plotComplete
      });
    }
  };

  const canProceedFromStep = (step: RiskMapStep): boolean => {
    switch (step) {
      case 1: return true;
      case 2: return selectedVariables.length > 0;
      case 3: return modelMetrics !== null;
      case 4: return modelAccepted !== null;
      case 5: return true;
      case 6: return true;
      default: return false;
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case 1:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-3xl flex items-center gap-2">
                    <Map className="h-8 w-8 text-purple-500 dark:text-purple-300" />
                    Risk Map Module
                  </CardTitle>
                  <CardDescription className="text-lg mt-2">
                    Generate and validate a global risk map
                  </CardDescription>
                </div>
                <Badge variant="secondary" className="text-sm px-3 py-1">
                  df_estimate Ready
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Process Overview */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <Target className="h-8 w-8 text-blue-500 dark:text-blue-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Validated Data</p>
                    <p className="text-xs text-muted-foreground">df_estimate input</p>
                  </CardContent>
                </Card>
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <Globe className="h-8 w-8 text-purple-500 dark:text-purple-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Global Model</p>
                    <p className="text-xs text-muted-foreground">Spatial risk estimation</p>
                  </CardContent>
                </Card>
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <MapPin className="h-8 w-8 text-green-500 dark:text-green-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Risk Map</p>
                    <p className="text-xs text-muted-foreground">DF4 + PLOT4</p>
                  </CardContent>
                </Card>
              </div>

              <Separator />

              {/* Dataset Preview */}
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">Validated Dataset Preview</h3>
                  <Badge variant="outline">
                    {validatedDataPreview.totalRows} rows
                  </Badge>
                </div>
                
                <div className="border rounded-lg overflow-hidden max-h-64 overflow-y-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        {validatedDataPreview.columns.map((column, index) => (
                          <TableHead key={index} className="sticky top-0 bg-background">{column}</TableHead>
                        ))}
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {validatedDataPreview.rows.map((row, index) => (
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
                  Showing first 5 rows of {validatedDataPreview.totalRows} validated results from previous module
                </p>
              </div>

              {/* Start Variable Selection */}
              <div className="text-center space-y-4 pt-6">
                <div className="p-6 bg-primary/10 rounded-lg border border-primary/20">
                  <Globe className="h-12 w-12 text-primary mx-auto mb-4" />
                  <h3 className="font-semibold mb-2">Ready to Generate Global Risk Map</h3>
                  <p className="text-sm text-muted-foreground mb-4">
                    Select exogenous variables to build a comprehensive spatial risk model
                    and generate downloadable risk map outputs.
                  </p>
                  <Button onClick={handleStartVariableSelection} size="lg" className="px-8">
                    <Target className="mr-2 h-5 w-5" />
                    Start Variable Selection
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
                <Target className="h-6 w-6 text-primary" />
                Select Exogenous Variables
              </CardTitle>
              <CardDescription>
                Choose variables to include in the global risk model
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Variables by Category */}
              <div className="space-y-6">
                {Object.entries(groupedVariables).map(([category, variables]) => (
                  <div key={category}>
                    <h3 className="font-medium text-sm text-muted-foreground uppercase tracking-wider mb-3">
                      {category} Variables
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {variables.map((variable) => (
                        <div
                          key={variable.id}
                          className="flex items-start space-x-3 p-3 border rounded-lg hover:bg-accent cursor-pointer"
                          onClick={() => handleVariableToggle(variable.id)}
                        >
                          <Checkbox
                            checked={selectedVariables.includes(variable.id)}
                            onChange={() => handleVariableToggle(variable.id)}
                          />
                          <div className="flex-1 min-w-0">
                            <p className="font-medium text-sm">{variable.name}</p>
                            <p className="text-xs text-muted-foreground">{variable.description}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              {/* Selection Summary */}
              {selectedVariables.length > 0 && (
                <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                  <p className="font-medium text-primary mb-2">
                    Selected Variables ({selectedVariables.length}):
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {selectedVariables.map(id => {
                      const variable = availableVariables.find(v => v.id === id);
                      return (
                        <Badge key={id} variant="outline" className="text-xs">
                          {variable?.name}
                        </Badge>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Estimate Global Model Button */}
              <div className="text-center pt-4">
                <Button 
                  onClick={estimateGlobalModel} 
                  disabled={selectedVariables.length === 0}
                  size="lg" 
                  className="px-8"
                >
                  <Globe className="mr-2 h-5 w-5" />
                  Estimate Global Model
                </Button>
              </div>
            </CardContent>
          </Card>
        );

      case 3:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Globe className="h-6 w-6 text-primary" />
                Estimating Global Model
              </CardTitle>
              <CardDescription>
                Building spatial risk model with selected variables
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="text-center space-y-6">
                <div className="p-8">
                  <Loader2 className="h-16 w-16 text-primary mx-auto mb-6 animate-spin" />
                  <h3 className="text-xl font-semibold mb-4">Estimating global model... Please wait.</h3>
                  <div className="space-y-3">
                    <div className="flex justify-between text-sm max-w-md mx-auto">
                      <span>Processing {selectedVariables.length} variables</span>
                      <span>{Math.round(estimationProgress)}%</span>
                    </div>
                    <Progress value={estimationProgress} className="w-full max-w-md mx-auto h-3" />
                  </div>
                  <p className="text-sm text-muted-foreground mt-4">
                    Building spatial weight matrix and computing risk predictions
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        );

      case 4:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-6 w-6 text-primary" />
                Validate Global Model
              </CardTitle>
              <CardDescription>
                Review model performance and decide next steps
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {modelMetrics && (
                <>
                  {/* Model Summary */}
                  <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                    <h3 className="font-medium text-primary mb-2">
                      Global Model Summary
                    </h3>
                    <div className="text-sm text-primary/80 space-y-1">
                      <p>Variables: {selectedVariables.length} exogenous factors</p>
                      <p>Spatial weights: Dynamic spatial matrix</p>
                      <p>Model type: Global spatial risk estimation</p>
                    </div>
                  </div>

                  {/* Model Metrics */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold text-green-500 dark:text-green-300 mb-2">
                          {(modelMetrics.rSquared * 100).toFixed(1)}%
                        </div>
                        <p className="text-sm text-muted-foreground">R² Score</p>
                        <div className="mt-2">
                          <Progress value={modelMetrics.rSquared * 100} className="h-2" />
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold text-primary mb-2">
                          {modelMetrics.mse.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">MSE</p>
                        <p className="text-xs text-muted-foreground mt-1">Mean Squared Error</p>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold text-amber-500 dark:text-amber-300 mb-2">
                          {modelMetrics.rmse.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">RMSE</p>
                        <p className="text-xs text-muted-foreground mt-1">Root Mean Squared Error</p>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold text-red-500 dark:text-red-300 mb-2">
                          {modelMetrics.mae.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">MAE</p>
                        <p className="text-xs text-muted-foreground mt-1">Mean Absolute Error</p>
                      </CardContent>
                    </Card>
                  </div>

                  {/* Decision Block */}
                  <div className="p-6 bg-gray-50 dark:bg-gray-800 rounded-lg border">
                    <h3 className="text-lg font-semibold mb-4 text-center">
                      Are you satisfied with this model?
                    </h3>
                    <p className="text-sm text-muted-foreground text-center mb-6">
                      The model shows {(modelMetrics.rSquared * 100).toFixed(1)}% variance explained (R²). 
                      You can proceed to generate outputs or re-select variables to improve the model.
                    </p>
                    
                    <div className="flex justify-center gap-4">
                      <Button onClick={handleRejectModel} variant="outline" size="lg">
                        <RefreshCw className="mr-2 h-5 w-5" />
                        Re-select Variables
                      </Button>
                      <Button onClick={handleAcceptModel} size="lg">
                        <CheckCircle className="mr-2 h-5 w-5" />
                        Proceed to Outputs
                      </Button>
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        );

      case 5:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Package className="h-6 w-6 text-primary" />
                Output Options
              </CardTitle>
              <CardDescription>
                What would you like to do with the model output?
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Model Context */}
              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <h3 className="font-medium text-green-800 dark:text-green-200 mb-2">
                  Global Model Ready
                </h3>
                <div className="text-sm text-green-700 dark:text-green-300 space-y-1">
                  <p>Variables: {selectedVariables.length} exogenous factors selected</p>
                  <p>Performance: R² = {(modelMetrics?.rSquared! * 100).toFixed(1)}%, MSE = {modelMetrics?.mse.toFixed(3)}</p>
                  <p>Output: Risk map ready for download and visualization</p>
                </div>
              </div>

              {/* Primary Output Actions */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Download Option */}
                <Card className={`border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer ${downloadComplete ? 'bg-primary/20' : ''}`}>
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                      {downloadComplete ? (
                        <CheckCircle className="h-8 w-8 text-primary" />
                      ) : (
                        <FileDown className="h-8 w-8 text-primary" />
                      )}
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Download Risk Map</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Save your risk map dataset as DF4 for external analysis and GIS applications
                      </p>
                    </div>
                    <Button 
                      onClick={handleDownloadRiskMap} 
                      disabled={isDownloading}
                      className="w-full"
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
                          DF4 Downloaded
                        </>
                      ) : (
                        <>
                          <Download className="mr-2 h-4 w-4" />
                          Download DF4
                        </>
                      )}
                    </Button>
                  </CardContent>
                </Card>

                {/* Plot Option */}
                <Card className={`border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer ${plotComplete ? 'bg-primary/20' : ''}`}>
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                      {plotComplete ? (
                        <CheckCircle className="h-8 w-8 text-primary" />
                      ) : (
                        <Map className="h-8 w-8 text-primary" />
                      )}
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Plot Risk Map</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Generate interactive visualization (PLOT4) of spatial risk distribution
                      </p>
                    </div>
                    <Button 
                      onClick={handlePlotRiskMap} 
                      disabled={isPlotting}
                      className="w-full"
                      variant={plotComplete ? "outline" : "outline"}
                    >
                      {isPlotting ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Generating...
                        </>
                      ) : plotComplete ? (
                        <>
                          <CheckCircle className="mr-2 h-4 w-4" />
                          PLOT4 Generated
                        </>
                      ) : (
                        <>
                          <BarChart3 className="mr-2 h-4 w-4" />
                          Create Plot
                        </>
                      )}
                    </Button>
                  </CardContent>
                </Card>
              </div>

              {/* Export All Option */}
              {(downloadComplete && plotComplete) ? (
                <div className="text-center p-4 bg-green-50 dark:bg-green-800 rounded-lg">
                  <p className="text-sm text-green-700 dark:text-green-300 font-medium">
                    🎉 All outputs successfully generated!
                  </p>
                </div>
              ) : (
                <div className="text-center">
                  <Button 
                    onClick={handleExportAll} 
                    disabled={isDownloading || isPlotting}
                    size="lg"
                    variant="secondary"
                  >
                    <Package className="mr-2 h-5 w-5" />
                    Export All Outputs
                  </Button>
                  <p className="text-xs text-muted-foreground mt-2">
                    Download DF4 and generate PLOT4 in one action
                  </p>
                </div>
              )}

              {/* Risk Map Plot Display */}
              {showPlot && plotComplete && (
                <div className="space-y-4">
                  <Separator />
                  <h4 className="font-medium">Risk Map Visualization (PLOT4)</h4>
                  <div className="border rounded-lg p-8 bg-gray-50 dark:bg-gray-800">
                    <div className="text-center space-y-4">
                      <Map className="h-24 w-24 text-gray-300 mx-auto" />
                      <h3 className="text-lg font-medium">Interactive Risk Map</h3>
                      <p className="text-sm text-muted-foreground max-w-md mx-auto">
                        Your spatial risk map has been generated showing risk distribution across the study area.
                        In a real implementation, this would display an interactive map with risk layers.
                      </p>
                      <div className="flex justify-center gap-2">
                        <Badge variant="outline">Heat Map</Badge>
                        <Badge variant="outline">Risk Zones</Badge>
                        <Badge variant="outline">Interactive</Badge>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Continue Button */}
              {(downloadComplete || plotComplete) && (
                <div className="text-center pt-4">
                  <Button onClick={handleProceedToNext} size="lg">
                    <ArrowRight className="mr-2 h-5 w-5" />
                    Continue to Summary
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        );

      case 6:
        return (
          <Card className="max-w-2xl mx-auto">
            <CardHeader className="text-center">
              <div className="w-16 h-16 bg-green-100 dark:bg-green-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-8 w-8 text-green-500 dark:text-green-300 " />
              </div>
              <CardTitle className="text-3xl">Risk Map Complete!</CardTitle>
              <CardDescription className="text-lg">
                Global risk map has been successfully generated
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center space-y-6">
              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <h3 className="font-medium text-green-800 dark:text-green-200 mb-2">
                  Module Summary
                </h3>
                <div className="text-sm text-green-700 dark:text-green-300 space-y-1">
                  <p>Selected Variables: {selectedVariables.length} exogenous factors</p>
                  <p>Model Performance: R² = {(modelMetrics?.rSquared! * 100).toFixed(1)}%</p>
                  <p>Downloads: {downloadComplete ? 'DF4 Downloaded' : 'Not downloaded'}</p>
                  <p>Visualization: {plotComplete ? 'PLOT4 Generated' : 'Not generated'}</p>
                </div>
              </div>

              {/* Action Summary */}
              {(downloadComplete || plotComplete) && (
                <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                  <h3 className="font-medium text-blue-800 dark:text-blue-200 mb-2">
                    Outputs Generated
                  </h3>
                  <div className="flex justify-center gap-4 text-sm">
                    {downloadComplete && (
                      <span className="flex items-center gap-1 text-blue-500 dark:text-blue-300">
                        <FileDown className="h-4 w-4" />
                        DF4 saved
                      </span>
                    )}
                    {plotComplete && (
                      <span className="flex items-center gap-1 text-blue-500 dark:text-blue-300">
                        <Map className="h-4 w-4" />
                        PLOT4 created
                      </span>
                    )}
                  </div>
                </div>
              )}

              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Button 
                  onClick={() => setCurrentStep(1)} 
                  variant="outline"
                  className="flex-1 sm:flex-none"
                >
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Restart Module
                </Button>
                
                <Button 
                  onClick={handleCompleteModule} 
                  className="flex-1 sm:flex-none"
                  size="lg"
                >
                  <ArrowRight className="mr-2 h-4 w-4" />
                  Complete Analysis
                </Button>
              </div>

              {onReturn && (
                <Button 
                  onClick={onReturn} 
                  variant="ghost"
                  className="mt-2"
                >
                  <Home className="mr-2 h-4 w-4" />
                  Return to Dashboard
                </Button>
              )}
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
      {currentStep > 1 && currentStep < 6 && currentStep !== 3 && currentStep !== 5 && (
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