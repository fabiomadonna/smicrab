"use client";

import { ReactNode, useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Loader2,
  Clock,
  Settings,
  CheckCircle,
  Database,
  BarChart3,
  Target,
  Shield,
  Map,
  AlertCircle,
  ChevronRight,
  TrendingUp,
  MapIcon,
  CheckCircle2,
  Info,
  FileText,
  Users,
  Activity,
} from "lucide-react";
import { Analysis, AnalysisVariable, AnalyzeStatus, ModuleName } from "@/types";
import { getDescribeModuleOutputsAction } from "@/actions/describe.actions";
import { ModelAvailability } from "@/types/describe";
import { getVariableDisplayName } from "@/lib/utils";

interface AnalysisLayoutProps {
  analysis: Analysis;
  isPolling: boolean;
  children: ReactNode;
}

interface ModuleInfo {
  name: ModuleName;
  title: string;
  description: string;
  icon: React.ReactNode;
  path: string;
  availability?: ModelAvailability;
  isLoaded: boolean;
}

export function AnalysisLayout({
  analysis,
  isPolling,
  children,
}: AnalysisLayoutProps) {
  const pathname = usePathname();
  const [moduleAvailability, setModuleAvailability] = useState<
    Record<string, ModelAvailability>
  >({});
  const [loadingModules, setLoadingModules] = useState<Set<string>>(new Set());

  const modules: ModuleInfo[] = [
    {
      name: ModuleName.LOAD_MODULE,
      title: "Analysis Summary",
      description: "Analysis summary and configuration",
      icon: <Info className="w-5 h-5" />,
      path: `/analysis/${analysis.id}`,
      availability: moduleAvailability[ModuleName.LOAD_MODULE],
      isLoaded: true,
    },
    {
      name: ModuleName.DESCRIBE_MODULE,
      title: "Describe Module",
      description: "Data exploration and visualization",
      icon: <BarChart3 className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/describe`,
      availability: moduleAvailability[ModuleName.DESCRIBE_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.DESCRIBE_MODULE]),
    },
    {
      name: ModuleName.ESTIMATE_MODULE,
      title: "Estimate Module",
      description: "Model parameter estimation",
      icon: <TrendingUp className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/estimate`,
      availability: moduleAvailability[ModuleName.ESTIMATE_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.ESTIMATE_MODULE]),
    },
    {
      name: ModuleName.VALIDATE_MODULE,
      title: "Validate Module",
      description: "Model validation and diagnostics",
      icon: <CheckCircle2 className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/validate`,
      availability: moduleAvailability[ModuleName.VALIDATE_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.VALIDATE_MODULE]),
    },
    {
      name: ModuleName.RISK_MAP_MODULE,
      title: "Risk Map Module",
      description: "Risk assessment and mapping",
      icon: <MapIcon className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/riskmap`,
      availability: moduleAvailability[ModuleName.RISK_MAP_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.RISK_MAP_MODULE]),
    },
  ];

  const allModules = [
    ModuleName.LOAD_MODULE,
    ModuleName.DESCRIBE_MODULE,
    ModuleName.ESTIMATE_MODULE,
    ModuleName.VALIDATE_MODULE,
    ModuleName.RISK_MAP_MODULE,
  ];

  // Load module availability data
  useEffect(() => {
    const loadModuleAvailability = async () => {
      // Load describe module availability (already implemented)
      if (
        !moduleAvailability[ModuleName.DESCRIBE_MODULE] &&
        !loadingModules.has(ModuleName.DESCRIBE_MODULE)
      ) {
        setLoadingModules((prev) =>
          new Set(prev).add(ModuleName.DESCRIBE_MODULE)
        );
        try {
          const response = await getDescribeModuleOutputsAction(analysis.id);
          if (response.success && response.data && analysis.model_type) {
            const availability =
              response.data.model_specific_availability[
                analysis.model_type as keyof typeof response.data.model_specific_availability
              ];
            setModuleAvailability((prev) => ({
              ...prev,
              [ModuleName.DESCRIBE_MODULE]: availability,
            }));
          }
        } catch (error) {
          console.error("Failed to load describe module availability:", error);
        } finally {
          setLoadingModules((prev) => {
            const newSet = new Set(prev);
            newSet.delete(ModuleName.DESCRIBE_MODULE);
            return newSet;
          });
        }
      }

      // TODO: Load other module availabilities when their APIs are ready
      // For now, we'll set them as available for demonstration
      const otherModules = [
        ModuleName.ESTIMATE_MODULE,
        ModuleName.VALIDATE_MODULE,
        ModuleName.RISK_MAP_MODULE,
      ];

      otherModules.forEach((moduleName) => {
        if (!moduleAvailability[moduleName]) {
          setModuleAvailability((prev) => ({
            ...prev,
            [moduleName]: {
              data_exports: true,
              spatial_distribution_plots: true,
              temporal_distribution_plots: true,
              summary_statistics_plots: true,
              statistics_data: true,
            },
          }));
        }
      });
    };

    loadModuleAvailability();
  }, [analysis.id, analysis.model_type, moduleAvailability, loadingModules]);

  const isModuleAvailable = (module: ModuleInfo): boolean => {
    if (!module.availability) return false;

    // A module is available if at least one of its features is available
    return Object.values(module.availability).some((available) => available);
  };

  const isCurrentModule = (modulePath: string): boolean => {
    return pathname === modulePath;
  };

  return (
    <div className="flex gap-6">
      {/* Sidebar */}
      <div className="w-80 space-y-6">
        {/* Analysis Modules */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 text-lg">
              <Database className="w-5 h-5" />
              Analysis Modules
            </CardTitle>
            <div className="text-sm text-muted-foreground">
              ID: {analysis.id.slice(-8)}
            </div>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="space-y-2">
              <Link href={modules[0].path}>
                <Button
                  variant={
                    isCurrentModule(modules[0].path) ? "default" : "ghost"
                  }
                  className={`w-full justify-start h-auto p-3 ${
                    isCurrentModule(modules[0].path)
                      ? "bg-primary text-primary-foreground"
                      : "hover:bg-muted"
                  }`}
                >
                  <div className="flex items-center gap-3 w-full">
                    <div
                      className={`shrink-0 ${
                        isCurrentModule(modules[0].path)
                          ? "text-primary-foreground"
                          : "text-primary"
                      }`}
                    >
                      {modules[0].icon}
                    </div>
                    <div className="text-left flex-1 min-w-0">
                      <div className="font-medium truncate">
                        {modules[0].title}
                      </div>
                      <div
                        className={`text-xs truncate ${
                          isCurrentModule(modules[0].path)
                            ? "text-primary-foreground/80"
                            : "text-muted-foreground"
                        }`}
                      >
                        {modules[0].description}
                      </div>
                    </div>
                    {isCurrentModule(modules[0].path) && (
                      <ChevronRight className="w-4 h-4 shrink-0" />
                    )}
                  </div>
                </Button>
              </Link>
              <Separator className="my-2" />

              {modules.slice(1).map((module, index) => {
                const isAvailable = isModuleAvailable(module);
                const isCurrent = isCurrentModule(module.path);
                const isLoading = loadingModules.has(module.name);

                return (
                  <div key={module.name}>
                    {index > 0 && <Separator className="my-2" />}

                    {isAvailable ? (
                      <Link href={module.path}>
                        <Button
                          variant={isCurrent ? "default" : "ghost"}
                          className={`w-full justify-start h-auto p-3 ${
                            isCurrent
                              ? "bg-primary text-primary-foreground"
                              : "hover:bg-muted"
                          }`}
                        >
                          <div className="flex items-center gap-3 w-full">
                            <div
                              className={`shrink-0 ${
                                isCurrent
                                  ? "text-primary-foreground"
                                  : "text-primary"
                              }`}
                            >
                              {module.icon}
                            </div>
                            <div className="text-left flex-1 min-w-0">
                              <div className="font-medium truncate">
                                {module.title}
                              </div>
                              <div
                                className={`text-xs truncate ${
                                  isCurrent
                                    ? "text-primary-foreground/80"
                                    : "text-muted-foreground"
                                }`}
                              >
                                {module.description}
                              </div>
                            </div>
                            {isCurrent && (
                              <ChevronRight className="w-4 h-4 shrink-0" />
                            )}
                          </div>
                        </Button>
                      </Link>
                    ) : (
                      <div className="p-3 rounded-lg bg-muted/50 border border-dashed">
                        <div className="flex items-center gap-3 w-full">
                          <div className="shrink-0 text-muted-foreground">
                            {isLoading ? (
                              <div className="animate-spin w-5 h-5 border-2 border-muted-foreground border-t-transparent rounded-full" />
                            ) : (
                              <AlertCircle className="w-5 h-5" />
                            )}
                          </div>
                          <div className="text-left flex-1 min-w-0">
                            <div className="font-medium text-muted-foreground truncate">
                              {module.title}
                            </div>
                            <div className="text-xs text-muted-foreground truncate">
                              {isLoading
                                ? "Loading availability..."
                                : "Not available for this model"}
                            </div>
                          </div>
                          <Badge
                            variant="secondary"
                            className="text-xs shrink-0"
                          >
                            N/A
                          </Badge>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <div className="flex-1">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold">SMICRAB Analysis</h1>
              <p className="text-muted-foreground">{analysis.model_type}</p>
            </div>
            <div className="flex items-center gap-2">
              {isPolling && (
                <div className="flex items-center gap-1 text-sm text-muted-foreground">
                  <Loader2 className="w-3 h-3 animate-spin" />
                  <span>Updating...</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {children}
      </div>
    </div>
  );
}
