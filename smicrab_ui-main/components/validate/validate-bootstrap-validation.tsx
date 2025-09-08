"use client";

import { useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PlotGroup } from "@/components/ui/plot-group";
import { BootstrapValidation } from "@/types/validate";

interface ValidateBootstrapValidationProps {
  data: BootstrapValidation;
  analysisId: string;
  isDynamic: boolean;
}

export function ValidateBootstrapValidation({
  data,
  analysisId,
  isDynamic,
}: ValidateBootstrapValidationProps) {
  // Flatten the nested structure to create tabs for each file
  const tabs = [
    // Bootstrap comparison files
    ...data.bootstrap_comparison.files.map((file, index) => ({
      id: `bootstrap_comparison_${index}`,
      label: file.name.replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase()),
      description: file.description || data.bootstrap_comparison.description,
      files: [file],
      category: "Bootstrap Comparison"
    })),
    // Parameter distribution files
    ...data.parameter_distribution.files.map((file, index) => ({
      id: `parameter_distribution_${index}`,
      label: file.name.replace(/_/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase()),
      description: file.description || data.parameter_distribution.description,
      files: [file],
      category: "Parameter Distribution"
    }))
  ];

  const [activeTab, setActiveTab] = useState(tabs[0]?.id || "");

  return (
    <div className="space-y-4">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="flex flex-wrap h-auto p-1 bg-muted rounded-lg">
          {tabs.map((tab) => (
            <TabsTrigger
              key={tab.id}
              value={tab.id}
              className="text-xs px-3 py-1 m-0.5"
              title={tab.label}
            >
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {tabs.map((tab) => (
          <TabsContent key={tab.id} value={tab.id} className="mt-6">
            <PlotGroup
              title={tab.label}
              description={tab.description}
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