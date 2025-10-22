"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ValidateModuleOutputs, ValidateModelSpecificAvailability, ValidateModelAvailability } from "@/types/validate";
import { ModelType } from "@/types/enums";
import { ValidateResidualStatistics } from "./validate-residual-statistics";
import { ValidateAutocorrelationTests } from "./validate-autocorrelation-tests";
import { ValidateNormalityTests } from "./validate-normality-tests";
import { ValidateBootstrapValidation } from "./validate-bootstrap-validation";

interface ValidateModuleClientProps {
  analysisId: string;
  outputs: ValidateModuleOutputs;
  modelAvailability: ValidateModelSpecificAvailability;
  modelType?: ModelType;
  isDynamic: boolean;
}

export function ValidateModuleClient({
  analysisId,
  outputs,
  modelAvailability,
  modelType,
  isDynamic,
}: ValidateModuleClientProps) {
  const [activeTab, setActiveTab] = useState("residual_summary_statistics");

  // Get availability for the current model
  const currentModelAvailability: ValidateModelAvailability = modelType 
    ? modelAvailability[modelType as keyof ValidateModelSpecificAvailability]
    : {
        residual_summary_statistics: false,
        autocorrelation_tests: false,
        normality_tests: false,
        bootstrap_validation: false,
      };

  const tabs = [
    {
      id: "residual_summary_statistics",
      label: "Residual Statistics",
      description: "Summary statistics plots for residual analysis",
      available: currentModelAvailability.residual_summary_statistics,
      component: (
        <ValidateResidualStatistics 
          data={outputs.residual_summary_statistics}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "autocorrelation_tests",
      label: "Autocorrelation Tests",
      description: "Ljung-Box autocorrelation test results",
      available: currentModelAvailability.autocorrelation_tests,
      component: (
        <ValidateAutocorrelationTests 
          data={outputs.autocorrelation_tests}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "normality_tests",
      label: "Normality Tests",
      description: "Jarque-Bera normality test results",
      available: currentModelAvailability.normality_tests,
      component: (
        <ValidateNormalityTests 
          data={outputs.normality_tests}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "bootstrap_validation",
      label: "Bootstrap Validation",
      description: "Bootstrap validation results for H-SDPD models",
      available: currentModelAvailability.bootstrap_validation,
      component: (
        <ValidateBootstrapValidation 
          data={outputs.bootstrap_validation}
          analysisId={analysisId}
          isDynamic={isDynamic}
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
            No validate module results are available for the selected model type.
          </CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          {tabs.map((tab) => (
            <TabsTrigger
              key={tab.id}
              value={tab.id}
              disabled={!tab.available}
              className="relative"
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