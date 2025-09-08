"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { EstimateModuleOutputs, EstimateModelSpecificAvailability, EstimateModelAvailability } from "@/types/estimate";
import { ModelType } from "@/types/enums";
import { EstimateCoefficientTables } from "./estimate-coefficient-tables";
import { EstimateCoefficientPlots } from "./estimate-coefficient-plots";
import { EstimateTimeSeriesPlots } from "./estimate-time-series-plots";
import { EstimateCsvDownloads } from "./estimate-csv-downloads";

interface EstimateModuleClientProps {
  analysisId: string;
  outputs: EstimateModuleOutputs;
  modelAvailability: EstimateModelSpecificAvailability;
  modelType?: ModelType;
  isDynamic: boolean;
}

export function EstimateModuleClient({
  analysisId,
  outputs,
  modelAvailability,
  modelType,
  isDynamic,
}: EstimateModuleClientProps) {
  const [activeTab, setActiveTab] = useState("coefficient_tables");

  // Get availability for the current model
  const currentModelAvailability: EstimateModelAvailability = modelType 
    ? modelAvailability[modelType as keyof EstimateModelSpecificAvailability]
    : {
        coefficient_tables: false,
        coefficient_plots: false,
        time_series_plots: false,
        csv_downloads: false,
      };

  const tabs = [
    {
      id: "coefficient_tables",
      label: "Coefficient Tables",
      description: "Interactive tables with estimated parameters",
      available: currentModelAvailability.coefficient_tables,
      component: (
        <EstimateCoefficientTables 
          data={outputs.coefficient_tables}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "coefficient_plots",
      label: "Coefficient Plots",
      description: "Spatial plots of estimated coefficients",
      available: currentModelAvailability.coefficient_plots,
      component: (
        <EstimateCoefficientPlots
          data={outputs.coefficient_plots}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "time_series_plots",
      label: "Time Series Plots",
      description: "Fitted and residual time series for selected locations",
      available: currentModelAvailability.time_series_plots,
      component: (
        <EstimateTimeSeriesPlots 
          data={outputs.time_series_plots}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "csv_downloads",
      label: "CSV Downloads",
      description: "Downloadable CSV files with estimation results",
      available: currentModelAvailability.csv_downloads,
      component: (
        <EstimateCsvDownloads 
          data={outputs.csv_downloads}
          analysisId={analysisId}
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
            No estimate module results are available for the selected model type.
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