"use client";

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Input } from "@/components/ui/input";
import { 
  CheckCircle,
  X,
  Download,
  BarChart3,
  ArrowRight,
  ArrowLeft,
  Play,
  Settings,
  Target,
  Loader2,
  RefreshCw,
  Home,
  Activity,
  TrendingUp,
  AlertTriangle,
  Gauge,
  TestTube2,
  FileCheck,
  Edit3
} from "lucide-react";

interface ValidateWizardProps {
  estimatedData?: any; // df_estimate from Estimate Module
  onComplete: (validatedData: any) => void;
  onReturn?: () => void;
}

type ValidateStep = 1 | 2 | 3 | 4 | 5 | 6 | 7;

interface ValidationSettings {
  method: string;
  testSize: number;
  randomSeed: number;
  threshold: number;
}

interface ValidationResults {
  accuracy: number;
  precision: number;
  recall: number;
  f1Score: number;
  passed: boolean;
}

interface DatasetPreview {
  columns: string[];
  rows: any[][];
  totalRows: number;
}

export function ValidateWizard({ estimatedData, onComplete, onReturn }: ValidateWizardProps) {
  const [currentStep, setCurrentStep] = useState<ValidateStep>(1);
  const [validationSettings, setValidationSettings] = useState<ValidationSettings>({
    method: 'k-fold',
    testSize: 20,
    randomSeed: 42,
    threshold: 0.85
  });
  const [isTesting, setIsTesting] = useState(false);
  const [testProgress, setTestProgress] = useState(0);
  const [validationResults, setValidationResults] = useState<ValidationResults | null>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const [downloadComplete, setDownloadComplete] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [modelAccepted, setModelAccepted] = useState(false);

  // Sample estimated data preview (df_estimate from Estimate Module)
  const estimateDataPreview: DatasetPreview = {
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

  const steps = [
    { number: 1, title: "Start", description: "Review estimated dataset" },
    { number: 2, title: "Settings", description: "Select testing options" },
    { number: 3, title: "Testing", description: "Run SPDP model test" },
    { number: 4, title: "Results", description: "Validate SPDP model" },
    { number: 5, title: "Success", description: "Validation accepted" },
    { number: 6, title: "Update", description: "Improve estimate" },
    { number: 7, title: "Complete", description: "Finalize validation" }
  ];

  const getCurrentStepInfo = () => {
    if (currentStep === 5 && validationResults?.passed) return steps[4]; // Success
    if (currentStep === 5 && !validationResults?.passed) return steps[5]; // Update
    if (currentStep === 6) return steps[6]; // Complete
    return steps[currentStep - 1];
  };

  const currentStepInfo = getCurrentStepInfo();
  const progressPercentage = ((currentStep - 1) / (steps.length - 1)) * 100;

  const handleNext = () => {
    if (currentStep < 7) {
      setCurrentStep((prev) => (prev + 1) as ValidateStep);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as ValidateStep);
    }
  };

  const handleSelectTestingOptions = () => {
    setCurrentStep(2);
  };

  const runTest = async () => {
    setCurrentStep(3);
    await new Promise(resolve => setTimeout(resolve, 100));
    
    setIsTesting(true);
    setTestProgress(0);

    // Simulate SPDP model testing process
    const testingSteps = [
      "Preparing test data...",
      "Splitting dataset...",
      "Running K-Fold validation...",
      "Calculating metrics...",
      "Evaluating model performance...",
      "Generating results..."
    ];

    for (let i = 0; i < testingSteps.length; i++) {
      await new Promise(resolve => setTimeout(resolve, 800));
      setTestProgress(((i + 1) / testingSteps.length) * 100);
    }

    // Generate validation results based on threshold
    const accuracy = 0.82 + Math.random() * 0.15; // Random between 0.82-0.97
    const precision = 0.78 + Math.random() * 0.18;
    const recall = 0.75 + Math.random() * 0.2;
    const f1Score = (2 * (precision * recall)) / (precision + recall);
    
    const results: ValidationResults = {
      accuracy: Math.min(accuracy, 0.99),
      precision: Math.min(precision, 0.99),
      recall: Math.min(recall, 0.99),
      f1Score: Math.min(f1Score, 0.99),
      passed: accuracy >= (validationSettings.threshold / 100)
    };

    setValidationResults(results);
    setIsTesting(false);
    setCurrentStep(4);
  };

  const handleAcceptValidation = () => {
    setCurrentStep(5);
  };

  const handleRejectValidation = () => {
    setCurrentStep(6);
  };

  const handleUpdateEstimate = async () => {
    setIsUpdating(true);
    // Simulate updating estimate
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsUpdating(false);
    // Reset to step 2 for re-testing
    setCurrentStep(2);
    setValidationResults(null);
  };

  const handleDownloadValidated = async () => {
    setIsDownloading(true);
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsDownloading(false);
    setDownloadComplete(true);
  };

  const handleProceedToRiskMap = () => {
    if (validationResults) {
      onComplete({
        ...estimateDataPreview,
        validated: true,
        validationResults: validationResults
      });
    }
  };

  const handleLowerThreshold = () => {
    // Lower the threshold and accept current model
    setValidationSettings(prev => ({
      ...prev,
      threshold: Math.round((validationResults?.accuracy || 0) * 100) - 1
    }));
    setModelAccepted(true);
    setCurrentStep(6);
  };

  const handleRetrain = () => {
    // Go back to previous module for retraining
    setCurrentStep(2);
    setValidationResults(null);
  };

  const getMetricColor = (value: number, threshold: number = 0.8) => {
    if (value >= threshold) return "text-green-500 dark:text-green-300";
    if (value >= threshold - 0.1) return "text-amber-500 dark:text-amber-300";
    return "text-red-500 dark:text-red-300";
  };

  const canProceedFromStep = (step: ValidateStep): boolean => {
    switch (step) {
      case 1: return true;
      case 2: return true;
      case 3: return validationResults !== null;
      case 4: return validationResults !== null;
      case 5: return validationResults?.passed || false;
      case 6: return true;
      case 7: return true;
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
                    <TestTube2 className="h-8 w-8 text-green-500 dark:text-green-300" />
                    Validate Module
                  </CardTitle>
                  <CardDescription className="text-lg mt-2">
                    Test and validate your SPDP model performance
                  </CardDescription>
                </div>
                <Badge variant="secondary" className="text-sm px-3 py-1">
                  df_estimate Ready
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Process Overview */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <Target className="h-8 w-8 text-blue-500 dark:text-blue-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Estimated Data</p>
                    <p className="text-xs text-muted-foreground">df_estimate input</p>
                  </CardContent>
                </Card>
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <Settings className="h-8 w-8 text-purple-500 dark:text-purple-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Configuration</p>
                    <p className="text-xs text-muted-foreground">Set test parameters</p>
                  </CardContent>
                </Card>
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <TestTube2 className="h-8 w-8 text-green-500 dark:text-green-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Validation</p>
                    <p className="text-xs text-muted-foreground">Run model tests</p>
                  </CardContent>
                </Card>
                <Card className="border-dashed">
                  <CardContent className="p-4 text-center">
                    <CheckCircle className="h-8 w-8 text-orange-500 dark:text-orange-300 mx-auto mb-2" />
                    <p className="font-medium text-sm">Results</p>
                    <p className="text-xs text-muted-foreground">Pass/Fail + DF3</p>
                  </CardContent>
                </Card>
              </div>

              <Separator />

              {/* Start Validation */}
              <div className="text-center space-y-4 pt-6">
                <div className="p-6 bg-primary/10 rounded-lg border border-primary/20">
                  <TestTube2 className="h-12 w-12 text-primary mx-auto mb-4" />
                  <h3 className="font-semibold mb-2">Ready to Validate SPDP Model</h3>
                  <p className="text-sm text-muted-foreground mb-4">
                    Test model accuracy and performance against quality thresholds.
                    Configure validation parameters and run comprehensive model tests.
                  </p>
                  <Button onClick={handleSelectTestingOptions} size="lg" className="px-8">
                    <Settings className="mr-2 h-5 w-5" />
                    Start Validation Setup
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
                  <Settings className="h-6 w-6 text-purple-500 dark:text-purple-300" />
                  Select Testing Options
                </CardTitle>
                <CardDescription>
                  Configure validation parameters for SPDP model testing
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Validation Method */}
                  <div className="space-y-3">
                    <Label className="text-base font-medium">Validation Method</Label>
                    <Select 
                      value={validationSettings.method} 
                      onValueChange={(value) => setValidationSettings(prev => ({ ...prev, method: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select validation method" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="k-fold">K-Fold Cross Validation</SelectItem>
                        <SelectItem value="hold-out">Hold-out Validation</SelectItem>
                        <SelectItem value="bootstrap">Bootstrap Validation</SelectItem>
                        <SelectItem value="time-series">Time Series Split</SelectItem>
                      </SelectContent>
                    </Select>
                    <p className="text-sm text-muted-foreground">
                      K-Fold provides robust validation by splitting data into multiple folds
                    </p>
                  </div>
  
                  {/* Test Size Percentage */}
                  <div className="space-y-3">
                    <Label className="text-base font-medium">Test Size: {validationSettings.testSize}%</Label>
                    <Slider
                      value={[validationSettings.testSize]}
                      onValueChange={([value]: number[]) => setValidationSettings(prev => ({ ...prev, testSize: value }))}
                      max={40}
                      min={10}
                      step={5}
                      className="w-full"
                    />
                    <p className="text-sm text-muted-foreground">
                      Percentage of data reserved for testing (10-40%)
                    </p>
                  </div>
  
                  {/* Random Seed */}
                  <div className="space-y-3">
                    <Label htmlFor="random-seed" className="text-base font-medium">Random Seed</Label>
                    <Input
                      id="random-seed"
                      type="number"
                      value={validationSettings.randomSeed}
                      onChange={(e) => setValidationSettings(prev => ({ ...prev, randomSeed: parseInt(e.target.value) || 42 }))}
                      className="w-full"
                    />
                    <p className="text-sm text-muted-foreground">
                      Ensures reproducible validation results
                    </p>
                  </div>
  
                  {/* Accuracy Threshold */}
                  <div className="space-y-3">
                    <Label className="text-base font-medium">Accuracy Threshold: {validationSettings.threshold}%</Label>
                    <Slider
                      value={[validationSettings.threshold]}
                      onValueChange={([value]: number[]) => setValidationSettings(prev => ({ ...prev, threshold: value }))}
                      max={95}
                      min={70}
                      step={5}
                      className="w-full"
                    />
                    <p className="text-sm text-muted-foreground">
                      Minimum accuracy required to pass validation
                    </p>
                  </div>
                </div>
  
                {/* Settings Summary */}
                <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-900">
                  <h3 className="font-medium text-blue-800 dark:text-blue-200 mb-2">
                    Validation Configuration
                  </h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground">Method</p>
                      <p className="font-medium">{validationSettings.method.toUpperCase()}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Test Size</p>
                      <p className="font-medium">{validationSettings.testSize}%</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Random Seed</p>
                      <p className="font-medium">{validationSettings.randomSeed}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Threshold</p>
                      <p className="font-medium">{validationSettings.threshold}%</p>
                    </div>
                  </div>
                </div>
  
                {/* Run Test Button */}
                <div className="text-center pt-4">
                  <Button onClick={runTest} size="lg" className="px-8">
                    <TestTube2 className="mr-2 h-5 w-5" />
                    Run Test
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
                <TestTube2 className="h-6 w-6 text-primary" />
                Running Validation
              </CardTitle>
              <CardDescription>
                Validating your SPDP model performance
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Validation info */}
              <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                <h3 className="font-medium text-primary mb-2">
                  Validation Process Started
                </h3>
                <div className="text-sm text-primary/80 space-y-1">
                  <p>Method: {validationSettings.method}</p>
                  <p>Threshold: {validationSettings.threshold}% accuracy required</p>
                  <p>Testing spatial-temporal model performance...</p>
                </div>
              </div>

              {/* Running validation */}
              <div className="text-center space-y-6">
                <div className="p-8">
                  <Loader2 className="h-16 w-16 text-primary mx-auto mb-6 animate-spin" />
                  <h3 className="text-xl font-semibold mb-4">Validating SPDP model...</h3>
                  <div className="space-y-3">
                    <div className="flex justify-between text-sm max-w-md mx-auto">
                      <span>Running validation tests</span>
                      <span>{Math.round(testProgress)}%</span>
                    </div>
                    <Progress value={testProgress} className="w-full max-w-md mx-auto h-3" />
                  </div>
                  <p className="text-sm text-muted-foreground mt-4">
                    Computing accuracy metrics and quality measures...
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
                <Gauge className="h-6 w-6 text-primary" />
                Validation Results
              </CardTitle>
              <CardDescription>
                SPDP model performance metrics and validation status
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {validationResults && (
                <>
                  {/* Validation Status */}
                  <div className={`p-4 rounded-lg border ${
                    validationResults.passed 
                      ? 'bg-green-500/10 dark:bg-green-900/20 border-green-500/20' 
                      : 'bg-red-500/10 border-red-500/20'
                  }`}>
                    <div className="flex items-center gap-2 mb-2">
                      {validationResults.passed ? (
                        <CheckCircle className="h-5 w-5 text-green-500 dark:text-green-300" />
                      ) : (
                        <AlertTriangle className="h-5 w-5 text-red-500 dark:text-red-300" />
                      )}
                      <span className={`font-medium ${
                        validationResults.passed 
                          ? 'text-green-500 dark:text-green-300' 
                          : 'text-red-500 dark:text-red-300'
                      }`}>
                        {validationResults.passed 
                          ? 'SPDP model validated successfully!' 
                          : 'Validation did not meet criteria.'}
                      </span>
                    </div>
                    <p className={`text-sm ${
                      validationResults.passed 
                        ? 'text-green-500 dark:text-green-300' 
                        : 'text-red-500 dark:text-red-300'
                    }`}>
                      {validationResults.passed 
                        ? `Model accuracy (${(validationResults.accuracy * 100).toFixed(1)}%) exceeds threshold (${validationSettings.threshold}%)`
                        : `Model accuracy (${(validationResults.accuracy * 100).toFixed(1)}%) below threshold (${validationSettings.threshold}%)`}
                    </p>
                  </div>

                  {/* Metrics Cards */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className={`text-3xl font-bold mb-2 ${getMetricColor(validationResults.accuracy, validationSettings.threshold / 100)}`}>
                          {(validationResults.accuracy * 100).toFixed(1)}%
                        </div>
                        <p className="text-sm text-muted-foreground">Accuracy</p>
                        <div className="mt-2">
                          <Progress value={validationResults.accuracy * 100} className="h-2" />
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold mb-2 text-primary">
                          {validationResults.precision.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">Precision</p>
                        <div className="mt-2">
                          <Progress value={validationResults.precision * 100} className="h-2" />
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold mb-2 text-primary">
                          {validationResults.recall.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">Recall</p>
                        <div className="mt-2">
                          <Progress value={validationResults.recall * 100} className="h-2" />
                        </div>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent className="p-6 text-center">
                        <div className="text-3xl font-bold mb-2 text-primary">
                          {validationResults.f1Score.toFixed(3)}
                        </div>
                        <p className="text-sm text-muted-foreground">F1-Score</p>
                        <div className="mt-2">
                          <Progress value={validationResults.f1Score * 100} className="h-2" />
                        </div>
                      </CardContent>
                    </Card>
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
                <Edit3 className="h-6 w-6 text-amber-500 dark:text-amber-300" />
                Model Adjustment
              </CardTitle>
              <CardDescription>
                Options to improve model performance
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Warning about validation failure */}
              <div className="p-4 bg-amber-500/10 rounded-lg border border-amber-500/20">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="h-5 w-5 text-amber-500 dark:text-amber-300" />
                  <span className="font-medium text-amber-700 dark:text-amber-300">
                    Model Performance Below Threshold
                  </span>
                </div>
                <p className="text-sm text-amber-500 dark:text-amber-300">
                  The validation results indicate that the model performance is below the required threshold. 
                  Consider adjusting parameters or retraining with different settings.
                </p>
              </div>

              {/* Current Performance Summary */}
              {validationResults && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <Card className="border-amber-500/20">
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-amber-500 dark:text-amber-300 mb-1">
                        {(validationResults.accuracy * 100).toFixed(1)}%
                      </div>
                      <p className="text-sm text-muted-foreground">Current Accuracy</p>
                    </CardContent>
                  </Card>
                  <Card className="border-green-500/20">
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-green-500 dark:text-green-300 mb-1">
                        {validationSettings.threshold}%
                      </div>
                      <p className="text-sm text-muted-foreground">Required Threshold</p>
                    </CardContent>
                  </Card>
                  <Card className="border-red-500/20">
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-red-500 dark:text-red-300 mb-1">
                        {(validationSettings.threshold - (validationResults.accuracy * 100)).toFixed(1)}%
                      </div>
                      <p className="text-sm text-muted-foreground">Gap to Close</p>
                    </CardContent>
                  </Card>
                  <Card className="border-primary/20">
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-primary mb-1">
                        {validationSettings.method.toUpperCase()}
                      </div>
                      <p className="text-sm text-muted-foreground">Validation Method</p>
                    </CardContent>
                  </Card>
                </div>
              )}

              {/* Update Options */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Lower Threshold Option */}
                <Card className="border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer">
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/5 rounded-full flex items-center justify-center mx-auto">
                      <Edit3 className="h-8 w-8 text-primary" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Adjust Threshold</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Lower the validation threshold to accept current model performance
                      </p>
                    </div>
                    <Button onClick={handleLowerThreshold} variant="outline" className="w-full">
                      <Settings className="mr-2 h-4 w-4" />
                      Lower Threshold
                    </Button>
                  </CardContent>
                </Card>

                {/* Retrain Model Option */}
                <Card className="border-2 border-dashed hover:border-solid hover:border-primary transition-colors cursor-pointer">
                  <CardContent className="p-6 text-center space-y-4">
                    <div className="w-16 h-16 bg-green-100 dark:bg-green-900/20 rounded-full flex items-center justify-center mx-auto">
                      <RefreshCw className="h-8 w-8 text-green-500 dark:text-green-300" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">Retrain Model</h3>
                      <p className="text-sm text-muted-foreground mb-4">
                        Go back to estimation with adjusted parameters for better performance
                      </p>
                    </div>
                    <Button onClick={handleRetrain} variant="outline" className="w-full">
                      <RefreshCw className="mr-2 h-4 w-4" />
                      Retrain Model
                    </Button>
                  </CardContent>
                </Card>
              </div>
            </CardContent>
          </Card>
        );

      case 6:
        return (
          <Card className="max-w-4xl mx-auto">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle className="h-6 w-6 text-green-500 dark:text-green-300" />
                Validation Complete
              </CardTitle>
              <CardDescription>
                Your SPDP model has been validated and is ready for risk mapping
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Success Message */}
              <div className="p-4 bg-green-500/10 rounded-lg border border-green-500/20">
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle className="h-5 w-5 text-green-500 dark:text-green-300" />
                  <span className="font-medium text-green-700 dark:text-green-300">
                    Model Validation Successful!
                  </span>
                </div>
                <div className="text-sm text-green-500 dark:text-green-300 space-y-1">
                  <p>✅ Model accuracy meets quality standards</p>
                  <p>✅ Spatial-temporal relationships validated</p>
                  <p>✅ Model ready for global risk mapping</p>
                  <p>📊 Output: DF3 (validated estimates) ready for next module</p>
                </div>
              </div>

              {/* Final validation summary */}
              {validationResults && (
                <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                  <h3 className="font-medium text-primary mb-2">Final Validation Summary</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground">Accuracy</p>
                      <p className="font-medium">{(validationResults.accuracy * 100).toFixed(1)}%</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Precision</p>
                      <p className="font-medium">{validationResults.precision.toFixed(3)}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Recall</p>
                      <p className="font-medium">{validationResults.recall.toFixed(3)}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">F1-Score</p>
                      <p className="font-medium">{validationResults.f1Score.toFixed(3)}</p>
                    </div>
                  </div>
                </div>
              )}

              <div className="text-center">
                <Button onClick={handleProceedToRiskMap} size="lg" className="px-8">
                  Continue to Risk Map Module
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Button>
              </div>
            </CardContent>
          </Card>
        );

      case 7:
        return (
          <Card className="max-w-2xl mx-auto">
            <CardHeader className="text-center">
              <div className="w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-8 w-8 text-green-500 dark:text-green-300" />
              </div>
              <CardTitle className="text-3xl">Validation Complete!</CardTitle>
              <CardDescription className="text-lg">
                You're ready to proceed to the next module
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center space-y-6">
              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <h3 className="font-medium text-green-800 dark:text-green-200 mb-2">
                  Final Validation Status
                </h3>
                <div className="text-sm text-green-700 dark:text-green-300 space-y-1">
                  <p>Dataset: df_estimate validated and ready</p>
                  <p>Status: {validationResults?.passed ? 'Passed all tests' : 'Updated and improved'}</p>
                  <p>Total Rows: {estimateDataPreview.totalRows}</p>
                  <p>Output Variables: {estimateDataPreview.columns.length}</p>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Button 
                  onClick={() => setCurrentStep(1)} 
                  variant="outline"
                  className="flex-1 sm:flex-none"
                >
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Restart Validation
                </Button>
                
                <Button 
                  onClick={handleProceedToRiskMap} 
                  className="flex-1 sm:flex-none"
                  size="lg"
                >
                  <ArrowRight className="mr-2 h-4 w-4" />
                  Go to RiskMap Module
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
      </div>

      {/* Step Content */}
      <div className="min-h-[500px]">
        {renderStepContent()}
      </div>

      {/* Navigation Buttons */}
      {currentStep > 1 && currentStep < 7 && currentStep !== 3 && currentStep !== 5 && (
        <div className="max-w-4xl mx-auto flex justify-between items-center pt-6 border-t">
          <Button
            onClick={handlePrevious}
            variant="outline"
            disabled={currentStep === 1 || isTesting || isUpdating}
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Previous
          </Button>
          
          <Button
            onClick={handleNext}
            disabled={!canProceedFromStep(currentStep) || isTesting || isUpdating}
          >
            Next
            <ArrowRight className="ml-2 h-4 w-4" />
          </Button>
        </div>
      )}
    </div>
  );
} 