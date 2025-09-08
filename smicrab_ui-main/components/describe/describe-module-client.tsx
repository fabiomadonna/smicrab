"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { DescribeModuleOutputs, ModelSpecificAvailability, ModelAvailability } from "@/types/describe";
import { ModelType } from "@/types/enums";
import { DescribeDataExports } from "./describe-data-exports";
import { DescribePlotGroup } from "./describe-plot-group";
import { DescribeStatisticsData } from "./describe-statistics-data";

interface DescribeModuleClientProps {
  analysisId: string;
  outputs: DescribeModuleOutputs;
  modelAvailability: ModelSpecificAvailability;
  modelType?: ModelType;
  isDynamic: boolean;
}

export function DescribeModuleClient({
  analysisId,
  outputs,
  modelAvailability,
  modelType,
  isDynamic,
}: DescribeModuleClientProps) {
  const [activeTab, setActiveTab] = useState("data_exports");

  // Get availability for the current model
  const currentModelAvailability: ModelAvailability = modelType 
    ? modelAvailability[modelType as keyof ModelSpecificAvailability]
    : {
        data_exports: false,
        spatial_distribution_plots: false,
        temporal_distribution_plots: false,
        summary_statistics_plots: false,
        statistics_data: false,
      };

  const tabs = [
    {
      id: "data_exports",
      label: "Data Exports",
      description: "Download processed data files",
      available: currentModelAvailability.data_exports,
      component: (
        <DescribeDataExports 
          data={outputs.data_exports}
          analysisId={analysisId}
        />
      ),
    },
    {
      id: "spatial_distribution_plots",
      label: "Spatial Distribution",
      description: "Spatial distribution of values at fixed dates",
      available: currentModelAvailability.spatial_distribution_plots,
      component: (
        <DescribePlotGroup
          plotGroup={outputs.spatial_distribution_plots}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "temporal_distribution_plots",
      label: "Temporal Distribution",
      description: "Temporal distribution using STL decomposition",
      available: currentModelAvailability.temporal_distribution_plots,
      component: (
        <DescribePlotGroup 
          plotGroup={outputs.temporal_distribution_plots}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "summary_statistics_plots",
      label: "Summary Statistics",
      description: "Statistical summaries and plots",
      available: currentModelAvailability.summary_statistics_plots,
      component: (
        <DescribePlotGroup 
          plotGroup={outputs.summary_statistics_plots}
          analysisId={analysisId}
          isDynamic={isDynamic}
        />
      ),
    },
    {
      id: "statistics_data",
      label: "Statistics Data",
      description: "JSON data files with summary statistics and time series",
      available: currentModelAvailability.statistics_data,
      component: (
        <DescribeStatisticsData
          data={outputs.statistics_data}
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
            No describe module results are available for the selected model type.
          </CardDescription>
        </CardHeader>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-5">
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