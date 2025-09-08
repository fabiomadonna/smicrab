"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  RiskMapModuleOutputs, 
  RiskMapModelAvailability,
  RiskMapModelSpecificAvailability 
} from "@/types/riskmap";
import { PlotGroup } from "@/components/ui/plot-group";

interface RiskMapModuleClientProps {
  analysisId: string;
  outputs: RiskMapModuleOutputs;
  modelAvailability: RiskMapModelSpecificAvailability;
  modelType?: string;
  isDynamic: boolean;
}

export function RiskMapModuleClient({
  analysisId,
  outputs,
  modelAvailability,
  modelType,
  isDynamic,
}: RiskMapModuleClientProps) {
  const [activeTab, setActiveTab] = useState("");

  // Get availability for the current model
  const currentModelAvailability: RiskMapModelAvailability = modelType 
    ? modelAvailability[modelType as keyof RiskMapModelSpecificAvailability]
    : {
        sens_slope_test: false,
        cox_snell_test: false,
        mann_kendall_test: false,
        seasonal_mann_kendall_test: false,
        prewhitened_mann_kendall_test: false,
        bias_corrected_prewhitened_test: false,
        robust_trend_newey_west: false,
        score_function_combination: false,
        majority_voting_combination: false,
        temporal_analysis: false,
        spatial_analysis: false,
        spatiotemporal_trend_analysis: false,
        spatial_regression_trend_parameters: false,
        spatiotemporal_fixed_effects_analysis: false,
        spatial_regression_fixed_effect_parameters: false,
      };

  const tabs = [
    {
      id: "sens_slope_test",
      label: "Sen's Slope Test",
      description: "Sen's slope test for trend analysis on deseasonalized time series",
      available: currentModelAvailability.sens_slope_test,
      component: (
        <PlotGroup
          files={outputs.sens_slope_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "cox_snell_test",
      label: "Cox-Snell Test",
      description: "Cox and Snell test for trend on deseasonalized time series",
      available: currentModelAvailability.cox_snell_test,
      component: (
        <PlotGroup
          files={outputs.cox_snell_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "mann_kendall_test",
      label: "Mann-Kendall Test",
      description: "Mann-Kendall trend test on deseasonalized time series",
      available: currentModelAvailability.mann_kendall_test,
      component: (
        <PlotGroup
          files={outputs.mann_kendall_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "seasonal_mann_kendall_test",
      label: "Seasonal Mann-Kendall",
      description: "Seasonal Mann-Kendall trend test on original time series",
      available: currentModelAvailability.seasonal_mann_kendall_test,
      component: (
        <PlotGroup
          files={outputs.seasonal_mann_kendall_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "prewhitened_mann_kendall_test",
      label: "Pre-whitened Mann-Kendall",
      description: "Pre-whitened Mann-Kendall trend test on deseasonalized time series",
      available: currentModelAvailability.prewhitened_mann_kendall_test,
      component: (
        <PlotGroup
          files={outputs.prewhitened_mann_kendall_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "bias_corrected_prewhitened_test",
      label: "Bias-corrected Pre-whitened",
      description: "Bias-corrected pre-whitened trend test on deseasonalized time series",
      available: currentModelAvailability.bias_corrected_prewhitened_test,
      component: (
        <PlotGroup
          files={outputs.bias_corrected_prewhitened_test.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "robust_trend_newey_west",
      label: "Robust Trend Newey-West",
      description: "Robust trend analysis using Newey-West estimator",
      available: currentModelAvailability.robust_trend_newey_west,
      component: (
        <PlotGroup
          files={outputs.robust_trend_newey_west.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "score_function_combination",
      label: "Score Function Combination",
      description: "Combination of trend tests using score functions",
      available: currentModelAvailability.score_function_combination,
      component: (
        <PlotGroup
          files={outputs.score_function_combination.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "majority_voting_combination",
      label: "Majority Voting Combination",
      description: "Combination of trend tests using majority voting",
      available: currentModelAvailability.majority_voting_combination,
      component: (
        <PlotGroup
          files={outputs.majority_voting_combination.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "temporal_analysis",
      label: "Temporal Analysis",
      description: "Temporal analysis outputs for Models 2 and 3",
      available: currentModelAvailability.temporal_analysis,
      component: (
        <PlotGroup
          files={outputs.temporal_analysis.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "spatial_analysis",
      label: "Spatial Analysis",
      description: "Spatial analysis outputs for Models 1, 2 and 3",
      available: currentModelAvailability.spatial_analysis,
      component: (
        <PlotGroup
          files={outputs.spatial_analysis.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "spatiotemporal_trend_analysis",
      label: "Spatiotemporal Trend Analysis",
      description: "Spatio-temporal SDPD trend analysis for Models 4, 5 and 6",
      available: currentModelAvailability.spatiotemporal_trend_analysis,
      component: (
        <PlotGroup
          files={outputs.spatiotemporal_trend_analysis.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "spatial_regression_trend_parameters",
      label: "Spatial Regression Trend Parameters",
      description: "Spatial regression of trend parameters for Models 4, 5 and 6",
      available: currentModelAvailability.spatial_regression_trend_parameters,
      component: (
        <PlotGroup
          files={outputs.spatial_regression_trend_parameters.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "spatiotemporal_fixed_effects_analysis",
      label: "Spatiotemporal Fixed Effects",
      description: "Spatio-temporal fixed effects analysis for Models 4, 5 and 6",
      available: currentModelAvailability.spatiotemporal_fixed_effects_analysis,
      component: (
        <PlotGroup
          files={outputs.spatiotemporal_fixed_effects_analysis.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
    {
      id: "spatial_regression_fixed_effect_parameters",
      label: "Spatial Regression Fixed Effect Parameters",
      description: "Spatial regression of fixed effect parameters for Models 4, 5 and 6",
      available: currentModelAvailability.spatial_regression_fixed_effect_parameters,
      component: (
        <PlotGroup
          files={outputs.spatial_regression_fixed_effect_parameters.files}
          analysisId={analysisId}
          isDynamic={isDynamic}
          showFunctionInfo={true}
        />
      ),
    },
  ];

  const availableTabs = tabs.filter(tab => tab.available);

  // Set default active tab to first available tab
  useEffect(() => {
    if (availableTabs.length > 0 && !availableTabs.find(tab => tab.id === activeTab)) {
      setActiveTab(availableTabs[0].id);
    }
  }, [availableTabs, activeTab, setActiveTab]);

  if (availableTabs.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>No Results Available</CardTitle>
          <CardDescription>
            No risk map module results are available for the selected model type.
          </CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="flex flex-wrap h-auto p-1 bg-muted rounded-lg gap-1">
          {availableTabs.map((tab) => (
            <TabsTrigger
              key={tab.id}
              value={tab.id}
              disabled={!tab.available}
              className="text-xs px-3 py-1 data-[state=active]:bg-background data-[state=active]:text-foreground"
            >
              {tab.label}
              {!tab.available && (
                <Badge variant="secondary" className="ml-2 text-xs">
                  N/A
                </Badge>
              )}
            </TabsTrigger>
          ))}
        </TabsList>

        {availableTabs.map((tab) => (
          <TabsContent key={tab.id} value={tab.id} className="mt-6">
            <Card>
              <CardHeader>
                <CardTitle>{tab.label}</CardTitle>
                <CardDescription>{tab.description}</CardDescription>
              </CardHeader>
              <CardContent>
                {tab.component}
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
} 