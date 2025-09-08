"use client";

/**
 * Estimate Module Step
 * Handles model type selection and variable configuration for estimate module
 */

import { useState, useTransition } from "react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Switch } from "@/components/ui/switch";
import { ModelType, AnalysisVariable } from "@/types/enums";
import { toast } from "sonner";
import type { CheckedState } from "@radix-ui/react-checkbox";
import {
  Database,
  HelpCircle,
  Loader2,
  TrendingUp,
  RefreshCw,
  Brain,
  Variable,
  Settings2,
} from "lucide-react";
import { AnalysisFormData } from "@/types/analysis";

interface StepProps {
  formData: Partial<AnalysisFormData>;
  onNext: (data: Partial<AnalysisFormData>) => void;
  onPrevious?: () => void;
  isLoading?: boolean;
  errors?: Record<string, string>;
  isLastStep?: boolean;
  onSubmit?: (data: Partial<AnalysisFormData>) => void;
}



// Model configuration interfaces
interface ModelConfiguration {
  endogenous: AnalysisVariable;
  covariates: Array<{
    variable: AnalysisVariable;
    lag: number;
  }>;
  modelType: ModelType;
  userSelectableEndogenous: boolean;
  userSelectableCovariates: boolean;
  userSelectableLags: boolean; // New flag for lag editability
}

// Model configurations based on updated specifications
const MODEL_CONFIGURATIONS: Record<string, ModelConfiguration> = {
  simple: {
    endogenous: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED, // Default, user can change
    covariates: [], // No covariates at all
    modelType: ModelType.MODEL1_SIMPLE,
    userSelectableEndogenous: true, // User-selected endogenous
    userSelectableCovariates: false, // No covariates available
    userSelectableLags: false,
  },
  autoregressive: {
    endogenous: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED,
    covariates: [], // No covariates
    modelType: ModelType.MODEL2_AUTOREGRESSIVE,
    userSelectableEndogenous: false, // Fixed endogenous
    userSelectableCovariates: false, // No covariates
    userSelectableLags: false,
  },
  mb_user: {
    endogenous: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED, // Default, user can change
    covariates: [], // User will add covariates, but lags are fixed at 0
    modelType: ModelType.MODEL3_MB_USER,
    userSelectableEndogenous: true, // User-selected endogenous
    userSelectableCovariates: true, // User-selected covariates
    userSelectableLags: false, // Lags fixed at 0
  },
  uhu: {
    endogenous: AnalysisVariable.LST_H18,
    covariates: [
      { variable: AnalysisVariable.MAXIMUM_AIR_TEMPERATURE_ADJUSTED, lag: 0 },
      { variable: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED, lag: 0 },
      { variable: AnalysisVariable.MEAN_RELATIVE_HUMIDITY_ADJUSTED, lag: 0 },
      { variable: AnalysisVariable.BLACK_SKY_ALBEDO_ALL_MEAN, lag: 0 }, // Changed to 0
    ],
    modelType: ModelType.Model4_UHI,
    userSelectableEndogenous: false, // Fixed endogenous
    userSelectableCovariates: false, // Fixed covariates
    userSelectableLags: false, // Fixed lags
  },
  rab: {
    endogenous: AnalysisVariable.BLACK_SKY_ALBEDO_ALL_MEAN,
    covariates: [
      { variable: AnalysisVariable.MAXIMUM_AIR_TEMPERATURE_ADJUSTED, lag: 0 },
      { variable: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED, lag: 0 },
      { variable: AnalysisVariable.MEAN_RELATIVE_HUMIDITY_ADJUSTED, lag: 0 },
    ],
    modelType: ModelType.MODEL5_RAB,
    userSelectableEndogenous: false, // Fixed endogenous
    userSelectableCovariates: false, // Fixed covariates
    userSelectableLags: false, // Fixed lags
  },
  hsdpd_user: {
    endogenous: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED, // Default, user can change
    covariates: [], // User will define covariates and lags
    modelType: ModelType.MODEL6_HSDPD_USER,
    userSelectableEndogenous: true, // User-selected endogenous
    userSelectableCovariates: true, // User-selected covariates
    userSelectableLags: true, // User-defined lags
  },
};

const ANALYSIS_VARIABLES = [
  {
    value: AnalysisVariable.MAXIMUM_AIR_TEMPERATURE_ADJUSTED,
    label: "Max Air Temperature",
  },
  {
    value: AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED,
    label: "Mean Air Temperature",
  },
  {
    value: AnalysisVariable.MINIMUM_AIR_TEMPERATURE_ADJUSTED,
    label: "Min Air Temperature",
  },
  {
    value: AnalysisVariable.MEAN_RELATIVE_HUMIDITY_ADJUSTED,
    label: "Mean Relative Humidity",
  },
  {
    value: AnalysisVariable.ACCUMULATED_PRECIPITATION_ADJUSTED,
    label: "Accumulated Precipitation",
  },
  {
    value: AnalysisVariable.MEAN_WIND_SPEED_ADJUSTED,
    label: "Mean Wind Speed",
  },
  {
    value: AnalysisVariable.BLACK_SKY_ALBEDO_ALL_MEAN,
    label: "Black Sky Albedo",
  },
  { value: AnalysisVariable.LST_H18, label: "Land Surface Temperature" },
];

// Sub-components
interface ModelTypeSelectionProps {
  selectedType: string;
  onTypeChange: (type: string) => void;
}

function ModelTypeSelection({
  selectedType,
  onTypeChange,
}: ModelTypeSelectionProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="simple-model"
          name="model-config"
          checked={selectedType === "simple"}
          onChange={() => onTypeChange("simple")}
          className="h-4 w-4"
        />
        <Label htmlFor="simple-model">Model 1 - Simple</Label>
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="autoregressive-model"
          name="model-config"
          checked={selectedType === "autoregressive"}
          onChange={() => onTypeChange("autoregressive")}
          className="h-4 w-4"
        />
        <Label htmlFor="autoregressive-model">Model 2 - Autoregressive</Label>
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="mb-user-model"
          name="model-config"
          checked={selectedType === "mb_user"}
          onChange={() => onTypeChange("mb_user")}
          className="h-4 w-4"
        />
        <Label htmlFor="mb-user-model">Model 3 - MB User</Label>
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="uhu-model"
          name="model-config"
          checked={selectedType === "uhu"}
          onChange={() => onTypeChange("uhu")}
          className="h-4 w-4"
        />
        <Label htmlFor="uhu-model">Model 4 - UHU</Label>
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="rab-model"
          name="model-config"
          checked={selectedType === "rab"}
          onChange={() => onTypeChange("rab")}
          className="h-4 w-4"
        />
        <Label htmlFor="rab-model">Model 5 - RAB</Label>
      </div>
      <div className="flex items-center space-x-2">
        <input
          type="radio"
          id="hsdpd-user-model"
          name="model-config"
          checked={selectedType === "hsdpd_user"}
          onChange={() => onTypeChange("hsdpd_user")}
          className="h-4 w-4"
        />
        <Label htmlFor="hsdpd-user-model">Model 6 - HSDPD User</Label>
      </div>
    </div>
  );
}

interface LoadingOverlayProps {
  isLoading: boolean;
}

function LoadingOverlay({ isLoading }: LoadingOverlayProps) {
  if (!isLoading) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-white/90 dark:bg-black/90">
      <div className="text-center space-y-4">
        <Loader2 className="h-16 w-16 mx-auto animate-spin text-blue-500 dark:text-blue-300" />
        <p className="text-lg font-medium text-gray-700 dark:text-gray-300">
          Configuring Model...
        </p>
        <p className="text-sm text-muted-foreground">
          This may take a few moments. Please wait.
        </p>
      </div>
    </div>
  );
}

interface PredefinedModelDisplayProps {
  modelType: string;
  configuration: ModelConfiguration;
  boolTrend: boolean;
  onBoolTrendChange: (checked: CheckedState) => void;
  boolDynamic: boolean;
  onBoolDynamicChange: (checked: CheckedState) => void;
  userCoeffChoice: number;
  onUserCoeffChoiceChange: (value: number) => void;
  // For user-selectable models
  selectedEndogenous?: AnalysisVariable;
  onEndogenousChange?: (variable: AnalysisVariable) => void;
  selectedCovariates?: Array<{ variable: AnalysisVariable; lag: number }>;
  onCovariatesChange?: (
    covariates: Array<{ variable: AnalysisVariable; lag: number }>
  ) => void;
}

function PredefinedModelDisplay({
  modelType,
  configuration,
  boolTrend,
  onBoolTrendChange,
  boolDynamic,
  onBoolDynamicChange,
  userCoeffChoice,
  onUserCoeffChoiceChange,
  selectedEndogenous,
  onEndogenousChange,
  selectedCovariates,
  onCovariatesChange,
}: PredefinedModelDisplayProps) {
  const getModelTitle = (type: string) => {
    switch (type) {
      case "simple":
        return "Simple Model Configuration";
      case "autoregressive":
        return "Autoregressive Model Configuration";
      case "mb_user":
        return "MB User Model Configuration";
      case "uhu":
        return "UHU Model Configuration";
      case "rab":
        return "RAB Model Configuration";
      case "hsdpd_user":
        return "HSDPD User Model Configuration";
      default:
        return "Model Configuration";
    }
  };

  const getModelDescription = (type: string) => {
    switch (type) {
      case "simple":
        return "Simple model with user-selected endogenous variable and no covariates";
      case "autoregressive":
        return "Autoregressive model with fixed endogenous variable and no covariates";
      case "mb_user":
        return "User-configurable MB model with selectable variables and fixed lags (0)";
      case "uhu":
        return "Pre-configured UHU model with fixed variables and zero lags";
      case "rab":
        return "Pre-configured RAB model with fixed variables and zero lags";
      case "hsdpd_user":
        return "Fully user-configurable HSDPD model with selectable variables and lags (Recommended)";
      default:
        return "Pre-configured model with optimized variable selection";
    }
  };

  const isUserSelectable =
    configuration.userSelectableEndogenous ||
    configuration.userSelectableCovariates;
  const displayEndogenous = selectedEndogenous || configuration.endogenous;
  const displayCovariates = selectedCovariates || configuration.covariates;

  return (
    <Card className="max-w-4xl mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-3">
          <Brain className="h-6 w-6" />
          {getModelTitle(modelType)}
        </CardTitle>
        <CardDescription>{getModelDescription(modelType)}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* User-selectable endogenous variable */}
          {configuration.userSelectableEndogenous && (
            <div className="space-y-2">
              <Label className="text-sm font-semibold flex items-center gap-2">
                <Variable className="h-4 w-4 text-blue-500" />
                Dependent Variable (Endogenous)
              </Label>
              <Select
                value={displayEndogenous}
                onValueChange={(value) =>
                  onEndogenousChange?.(value as AnalysisVariable)
                }
              >
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="Select dependent variable" />
                </SelectTrigger>
                <SelectContent>
                  {ANALYSIS_VARIABLES.map((variable) => (
                    <SelectItem key={variable.value} value={variable.value}>
                      {variable.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Variables table */}
          <div className="space-y-2">
            <Label className="text-sm font-semibold">Model Variables</Label>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Variable</TableHead>
                  <TableHead>Type</TableHead>
                  {/* Only show Lag column if model has covariates or can have covariates */}
                  {(configuration.userSelectableCovariates || displayCovariates.length > 0) && (
                    <TableHead>Lag</TableHead>
                  )}
                  {configuration.userSelectableCovariates && (
                    <TableHead>Action</TableHead>
                  )}
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow>
                  <TableCell className="font-medium">
                    {
                      ANALYSIS_VARIABLES.find(
                        (v) => v.value === displayEndogenous
                      )?.label
                    }
                  </TableCell>
                  <TableCell>
                    <Badge variant="default">Endogenous Variable</Badge>
                  </TableCell>
                  {/* Only show lag cell if model has covariates or can have covariates */}
                  {(configuration.userSelectableCovariates || displayCovariates.length > 0) && (
                    <TableCell>-</TableCell>
                  )}
                  {configuration.userSelectableCovariates && (
                    <TableCell>-</TableCell>
                  )}
                </TableRow>
                {displayCovariates.map((covariate, index) => (
                  <TableRow key={index}>
                    <TableCell className="font-medium">
                      {configuration.userSelectableCovariates ? (
                        <Select
                          value={covariate.variable}
                          onValueChange={(value) => {
                            const newCovariates = [...displayCovariates];
                            newCovariates[index] = {
                              ...covariate,
                              variable: value as AnalysisVariable,
                            };
                            onCovariatesChange?.(newCovariates);
                          }}
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {ANALYSIS_VARIABLES.filter((v) => {
                              // Filter out endogenous variable
                              if (v.value === displayEndogenous) return false;

                              // Filter out variables already used in other covariates
                              // But allow the current covariate's variable
                              return !displayCovariates.some(
                                (c, i) => i !== index && c.variable === v.value
                              );
                            }).map((variable) => (
                              <SelectItem
                                key={variable.value}
                                value={variable.value}
                              >
                                {variable.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      ) : (
                        ANALYSIS_VARIABLES.find(
                          (v) => v.value === covariate.variable
                        )?.label
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">Exogenous Covariate</Badge>
                    </TableCell>
                    {/* Only show lag cell if model has covariates or can have covariates */}
                    {(configuration.userSelectableCovariates || displayCovariates.length > 0) && (
                      <TableCell>
                        {configuration.userSelectableLags ? (
                          <Input
                            type="number"
                            min="0"
                            max="4"
                            value={covariate.lag}
                            onChange={(e) => {
                              const newCovariates = [...displayCovariates];
                              newCovariates[index] = {
                                ...covariate,
                                lag: parseInt(e.target.value) || 0,
                              };
                              onCovariatesChange?.(newCovariates);
                            }}
                            className="w-20"
                          />
                        ) : (
                          <Badge variant="outline" className="text-xs">
                            {covariate.lag}
                          </Badge>
                        )}
                      </TableCell>
                    )}
                    {configuration.userSelectableCovariates && (
                      <TableCell>
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => {
                            const newCovariates = displayCovariates.filter(
                              (_, i) => i !== index
                            );
                            onCovariatesChange?.(newCovariates);
                          }}
                        >
                          Remove
                        </Button>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
                            </TableBody>
            </Table>

            {/* Message for models with no covariates */}
            {!configuration.userSelectableCovariates && displayCovariates.length === 0 && (
              <div className="text-center p-4 bg-muted/50 rounded-lg border border-dashed">
                <p className="text-sm text-muted-foreground">
                  This model does not support covariate variables
                </p>
              </div>
            )}

            {/* Add covariate button for user-selectable models */}
            <div className="flex flex-col items-center mt-4 border-t pt-4 space-y-2">
              {configuration.userSelectableCovariates && (
                <>
                  <Button
                    className="m-auto"
                    variant="default"
                    size="sm"
                    onClick={() => {
                      // Filter out variables that are already used as covariates or as endogenous
                      const availableVariables = ANALYSIS_VARIABLES.filter(
                        (v) =>
                          v.value !== displayEndogenous &&
                          !displayCovariates.some((c) => c.variable === v.value)
                      );
                      if (availableVariables.length > 0) {
                        // For models with non-selectable lags, always set lag to 0
                        const defaultLag = configuration.userSelectableLags ? 0 : 0;
                        const newCovariates = [
                          ...displayCovariates,
                          { variable: availableVariables[0].value, lag: defaultLag },
                        ];
                        onCovariatesChange?.(newCovariates);
                      }
                    }}
                    disabled={
                      ANALYSIS_VARIABLES.filter(
                        (v) =>
                          v.value !== displayEndogenous &&
                          !displayCovariates.some((c) => c.variable === v.value)
                      ).length === 0
                    }
                  >
                    Add Covariate
                  </Button>
                  {!configuration.userSelectableLags && (
                    <p className="mt-2 text-xs text-muted-foreground text-center">
                      Note: All lag values are fixed at 0 for this model
                    </p>
                  )}
                </>
              )}
            </div>
          </div>

          {/* Model options */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-6 pt-4 border-t">
            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <Label htmlFor="bool_trend" className="text-sm font-medium">
                  Include Trend
                </Label>
                <p className="text-xs text-muted-foreground">
                  Temporal trend component
                </p>
              </div>
              <Switch
                id="bool_trend"
                checked={boolTrend}
                onCheckedChange={onBoolTrendChange}
              />
            </div>

            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div>
                <Label htmlFor="bool_dynamic" className="text-sm font-medium">
                  Dynamic Output
                </Label>
                <p className="text-xs text-muted-foreground">
                  Interactive HTML output
                </p>
              </div>
              <Switch
                id="bool_dynamic"
                checked={boolDynamic}
                onCheckedChange={onBoolDynamicChange}
              />
            </div>

            <div className="space-y-2">
              <Label
                htmlFor="user_coeff_choice"
                className="text-sm font-medium"
              >
                Coefficient Choice
              </Label>
              <Input
                id="user_coeff_choice"
                type="number"
                step="0.1"
                min="0"
                value={userCoeffChoice}
                onChange={(e) =>
                  onUserCoeffChoiceChange(parseFloat(e.target.value))
                }
                placeholder="1.0"
                className="w-full"
              />
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export function EstimateModuleStep({
  formData,
  onNext,
  onPrevious,
  isLoading,
  errors,
}: StepProps) {
  const [isPending, startTransition] = useTransition();

  // Model configuration state
  const [modelConfigurationType, setModelConfigurationType] =
    useState<string>("hsdpd_user");
  const [selectedEndogenous, setSelectedEndogenous] =
    useState<AnalysisVariable>(
      formData.endogenous_variable ??
        AnalysisVariable.MEAN_AIR_TEMPERATURE_ADJUSTED
    );
  const [selectedCovariates, setSelectedCovariates] = useState<
    Array<{ variable: AnalysisVariable; lag: number }>
  >(
    formData.covariate_variables?.map((v, i) => ({
      variable: v,
      lag: (formData as any).covariate_legs?.[i] || 0,
    })) || []
  );
  const [boolTrend, setBoolTrend] = useState(formData.bool_trend ?? true);
  const [boolDynamic, setBoolDynamic] = useState(formData.bool_dynamic ?? true);
  const [userCoeffChoice, setUserCoeffChoice] = useState(
    formData.user_coeff_choice ?? 1.0
  );
  const [isModelConfigLoading, setIsModelConfigLoading] = useState(false);

  // Apply predefined model configuration
  const applyPredefinedModel = (modelKey: string) => {
    const config = MODEL_CONFIGURATIONS[modelKey];
    if (!config) return;

    // Set endogenous variable
    if (!config.userSelectableEndogenous) {
      setSelectedEndogenous(config.endogenous);
    } else {
      // For user-selectable endogenous, set default but allow modification
      setSelectedEndogenous(config.endogenous);
    }

    // Set covariates
    if (!config.userSelectableCovariates) {
      // Fixed covariates (including empty array for models with no covariates)
      setSelectedCovariates(config.covariates);
    } else {
      // User-selectable covariates - start with empty array for user to add
      setSelectedCovariates([]);
    }
  };

  // Handle model configuration type change
  const handleModelConfigurationChange = (type: string) => {
    setModelConfigurationType(type);
    applyPredefinedModel(type);
  };

  const handleBoolTrendChange = (checked: CheckedState) => {
    setBoolTrend(checked === true);
  };

  const handleBoolDynamicChange = (checked: CheckedState) => {
    setBoolDynamic(checked === true);
  };

  const handleUserCoeffChoiceChange = (value: number) => {
    setUserCoeffChoice(value);
  };

  const handleEndogenousChange = (variable: AnalysisVariable) => {
    setSelectedEndogenous(variable);
    // Remove any covariates that are the same as the new endogenous variable
    setSelectedCovariates((prev) =>
      prev.filter((c) => c.variable !== variable)
    );
  };

  const handleCovariatesChange = (
    covariates: Array<{ variable: AnalysisVariable; lag: number }>
  ) => {
    setSelectedCovariates(covariates);
  };

  const handleNext = () => {
    if (!selectedEndogenous) {
      toast.error("Missing Information", {
        description: "Please select an endogenous variable",
      });
      return;
    }

    const config = MODEL_CONFIGURATIONS[modelConfigurationType];
    
    // Only validate covariates for models that support them
    if (config.userSelectableCovariates && selectedCovariates.length === 0) {
      toast.error("Missing Information", {
        description: "Please select at least one covariate variable",
      });
      return;
    }

    setIsModelConfigLoading(true);

    startTransition(async () => {
      try {
        const stepData: Partial<AnalysisFormData> = {
          model_type: config.modelType,
          endogenous_variable: selectedEndogenous,
          covariate_variables: selectedCovariates.map((c) => c.variable),
          covariate_legs: selectedCovariates.map((c) => c.lag),
          bool_trend: boolTrend,
          bool_dynamic: boolDynamic,
          user_coeff_choice: userCoeffChoice,
        };

        onNext(stepData);
      } catch (error) {
        console.error("Model configuration error:", error);
        const errorMessage =
          error instanceof Error
            ? error.message
            : "An unexpected error occurred";
        toast.error("Configuration Error", {
          description: errorMessage,
        });
      } finally {
        setIsModelConfigLoading(false);
      }
    });
  };

  // Initialize with default model on first load
  useState(() => {
    applyPredefinedModel("hsdpd_user");
  });

  const currentConfig = MODEL_CONFIGURATIONS[modelConfigurationType];

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <LoadingOverlay isLoading={isModelConfigLoading} />

      {/* Model Type Selection */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg flex items-center gap-2">
            <Settings2 className="h-5 w-5" />
            Model Type Selection
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ModelTypeSelection
            selectedType={modelConfigurationType}
            onTypeChange={handleModelConfigurationChange}
          />
        </CardContent>
      </Card>

      {/* Model Configuration Display */}
      <PredefinedModelDisplay
        modelType={modelConfigurationType}
        configuration={currentConfig}
        boolTrend={boolTrend}
        onBoolTrendChange={handleBoolTrendChange}
        boolDynamic={boolDynamic}
        onBoolDynamicChange={handleBoolDynamicChange}
        userCoeffChoice={userCoeffChoice}
        onUserCoeffChoiceChange={handleUserCoeffChoiceChange}
        selectedEndogenous={selectedEndogenous}
        onEndogenousChange={handleEndogenousChange}
        selectedCovariates={selectedCovariates}
        onCovariatesChange={handleCovariatesChange}
      />

      {/* Model Summary */}
      {selectedEndogenous && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Settings2 className="h-5 w-5" />
              Configuration Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="p-4 rounded-lg border space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-medium text-blue-800 dark:text-blue-300">
                  Model Type:
                </span>
                <Badge variant="outline">{currentConfig.modelType}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="font-medium text-blue-800 dark:text-blue-300">
                  Endogenous:
                </span>
                <Badge variant="outline">
                  {
                    ANALYSIS_VARIABLES.find(
                      (v) => v.value === selectedEndogenous
                    )?.label
                  }
                </Badge>
              </div>
              <div className="grid grid-cols-3 gap-2">
                <span className="font-medium text-blue-800 dark:text-blue-300">
                  Exogenous:
                </span>
                <div className="col-span-2 space-x-1 space-y-1 flex flex-wrap justify-end">
                  {selectedCovariates.map((covariate, index) => (
                    <Badge key={index} variant="secondary" className="text-xs">
                      {
                        ANALYSIS_VARIABLES.find(
                          (v) => v.value === covariate.variable
                        )?.label
                      }{" "}
                      (lag: {covariate.lag})
                    </Badge>
                  ))}
                  {selectedCovariates.length === 0 && (
                    <Badge variant="secondary" className="text-xs">
                      None
                    </Badge>
                  )}
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span className="font-medium text-blue-800 dark:text-blue-300">
                  Include Trend:
                </span>
                <Badge variant={boolTrend ? "default" : "secondary"}>
                  {boolTrend ? "Yes" : "No"}
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="font-medium text-blue-800 dark:text-blue-300">
                  Dynamic Output:
                </span>
                <Badge variant={boolDynamic ? "default" : "secondary"}>
                  {boolDynamic ? "Yes" : "No"}
                </Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Navigation Buttons */}
      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={onPrevious}
          disabled={
            !onPrevious || isLoading || isPending || isModelConfigLoading
          }
        >
          Previous
        </Button>
        <Button
          onClick={handleNext}
          disabled={
            isLoading ||
            isPending ||
            isModelConfigLoading ||
            !selectedEndogenous
          }
          size="lg"
        >
          {isPending || isModelConfigLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Configuring...
            </>
          ) : (
            "Next: Validate Module"
          )}
        </Button>
      </div>
    </div>
  );
}
