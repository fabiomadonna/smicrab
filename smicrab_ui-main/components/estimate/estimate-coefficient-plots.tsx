"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { CoefficientPlots } from "@/types/estimate";
import { PlotGroup } from "@/components/ui/plot-group";

interface EstimateCoefficientPlotsProps {
  data: CoefficientPlots;
  analysisId: string;
  isDynamic: boolean;
}

export function EstimateCoefficientPlots({
  data,
  analysisId,
  isDynamic,
}: EstimateCoefficientPlotsProps) {
  // Flatten structure: instead of nested tabs, combine all files into main level tabs
  // Convert covariate_plots to individual tabs, prefix lambda plots, etc.
  
  const createFlattenedTabs = () => {
    const tabs: Array<{
      id: string;
      label: string;
      files: any[];
      description: string;
    }> = [];
    
    // Add trend plots
    if (data.trend_plots && data.trend_plots.length > 0) {
      data.trend_plots.forEach((file, index) => {
        tabs.push({
          id: `trend-${index}`,
          label: "Trend",
          files: [file],
          description: "Spatial plots of trend coefficient estimates"
        });
      });
    }
    
    // Add covariate plots - each variable becomes a separate tab
    if (data.covariate_plots && data.covariate_plots.length > 0) {
      data.covariate_plots.forEach((file, index) => {
        tabs.push({
          id: `covariate-${index}`,
          label: `covariate ${index + 1}`,
          files: [file],
          description: "Spatial plots of covariate coefficients"
        });
      });
    }
    
    // Add spatial autocorrelation plots - each lambda becomes a separate tab
    if (data.spatial_autocorrelation_plots && data.spatial_autocorrelation_plots.length > 0) {
      data.spatial_autocorrelation_plots.forEach((file, index) => {
        tabs.push({
          id: `lambda-${index}`,
          label: `Lambda ${index}`,
          files: [file],
          description: "Spatial autocorrelation parameters"
        });
      });
    }
    
    // Add fixed effects plots
    if (data.fixed_effects_plots && data.fixed_effects_plots.length > 0) {
      data.fixed_effects_plots.forEach((file, index) => {
        tabs.push({
          id: `fixed-${index}`,
          label: "Fixed Effects",
          files: [file],
          description: "Spatial fixed effects estimates"
        });
      });
    }
    
    return tabs;
  };

  const flattenedTabs = createFlattenedTabs();
  const [activeTab, setActiveTab] = useState(flattenedTabs[0]?.id || "");

  useEffect(() => {
    if (flattenedTabs.length > 0 && !flattenedTabs.find(tab => tab.id === activeTab)) {
      setActiveTab(flattenedTabs[0].id);
    }
  }, [flattenedTabs, activeTab]);

  if (flattenedTabs.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-muted-foreground">No coefficient plots available</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">      
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="flex flex-wrap h-auto p-1 bg-muted rounded-lg">
          {flattenedTabs.map((tab) => (
            <TabsTrigger
              key={tab.id}
              value={tab.id}
              className="text-xs px-3 py-1 m-0.5"
            >
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {flattenedTabs.map((tab) => (
          <TabsContent key={tab.id} value={tab.id} className="mt-4">
            <PlotGroup
              files={tab.files}
              analysisId={analysisId}
              isDynamic={isDynamic}
              showFunctionInfo={true}
            />
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
} 