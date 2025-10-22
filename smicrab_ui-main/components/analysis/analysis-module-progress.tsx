"use client";

import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";
import { ModuleName } from "@/types/enums";

interface AnalysisModuleProgressProps {
  currentModule: ModuleName;
  title?: string;
}

export function AnalysisModuleProgress({
  currentModule,
  title = "Analysis Progress",
}: AnalysisModuleProgressProps) {
  // Define steps for the analysis modules
  const modules = [
    { module: ModuleName.LOAD_MODULE, label: "Data Module" },
    { module: ModuleName.DESCRIBE_MODULE, label: "Describe Module" },
    { module: ModuleName.ESTIMATE_MODULE, label: "Estimate Module" },
    { module: ModuleName.VALIDATE_MODULE, label: "Validate Module" },
    { module: ModuleName.RISK_MAP_MODULE, label: "Risk Map Module" },
  ];

  const currentModuleIndex = modules.findIndex(
    (m) => m.module === currentModule
  );
  const completedModules = currentModuleIndex;
  const progressPercentage = (completedModules / (modules.length - 1)) * 100;

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center space-y-4 mb-8">
        <div className="space-y-2">
          <h2 className="text-xl font-semibold">{title}</h2>
          <div className="w-full max-w-md mx-auto">
            <Progress value={progressPercentage} className="h-2" />
          </div>
        </div>
      </div>

      <div className="flex justify-center mb-8 overflow-auto">
        <div className="flex items-center space-x-2">
          {modules.map((module, index) => (
            <div key={module.module} className="flex items-center">
              <div
                className={cn(
                  "w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium",
                  index < currentModuleIndex
                    ? "bg-green-500 text-white"
                    : index === currentModuleIndex
                    ? "bg-blue-500 text-white"
                    : "bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-300"
                )}
              >
                {index + 1}
              </div>
              {index < modules.length - 1 && (
                <div
                  className={cn(
                    "w-8 h-0.5 mx-2",
                    index < currentModuleIndex
                      ? "bg-green-500"
                      : "bg-gray-200 dark:bg-gray-700"
                  )}
                />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
