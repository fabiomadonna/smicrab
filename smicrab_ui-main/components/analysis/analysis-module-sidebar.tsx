"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { 
  BarChart3, 
  TrendingUp, 
  CheckCircle2, 
  MapIcon, 
  Database,
  AlertCircle,
  ChevronRight,
  Loader2,
  CheckCircle,
  Clock,
  Target,
  Shield,
  Map
} from "lucide-react";
import { Analysis, ModuleName, AnalyzeStatus } from "@/types";
import { getDescribeModuleOutputsAction } from "@/actions/describe.actions";
import { getEstimateModuleOutputsAction } from "@/actions/estimate.actions";
import { getValidateModuleOutputsAction } from "@/actions/validate.actions";
import { getRiskMapModuleOutputsAction } from "@/actions/riskmap.actions";
import { ModelAvailability } from "@/types/describe";
import { EstimateModelAvailability } from "@/types/estimate";
import { ValidateModelAvailability } from "@/types/validate";
import { RiskMapModelAvailability } from "@/types/riskmap";

interface AnalysisModuleSidebarProps {
  analysis: Analysis;
}

interface ModuleInfo {
  name: ModuleName;
  title: string;
  description: string;
  icon: React.ReactNode;
  path: string;
  availability?: ModelAvailability | EstimateModelAvailability | ValidateModelAvailability | RiskMapModelAvailability | any;
  isLoaded: boolean;
}

export function AnalysisModuleSidebar({ analysis }: AnalysisModuleSidebarProps) {
  const pathname = usePathname();
  const [moduleAvailability, setModuleAvailability] = useState<Record<string, any>>({});
  const [loadingModules, setLoadingModules] = useState<Set<string>>(new Set());

  const modules: ModuleInfo[] = [
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
      icon: <Target className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/estimate`,
      availability: moduleAvailability[ModuleName.ESTIMATE_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.ESTIMATE_MODULE]),
    },
    {
      name: ModuleName.VALIDATE_MODULE,
      title: "Validate Module",
      description: "Model validation and diagnostics", 
      icon: <Shield className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/validate`,
      availability: moduleAvailability[ModuleName.VALIDATE_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.VALIDATE_MODULE]),
    },
    {
      name: ModuleName.RISK_MAP_MODULE,
      title: "Risk Map Module",
      description: "Risk assessment and mapping",
      icon: <Map className="w-5 h-5" />,
      path: `/analysis/${analysis.id}/riskmap`,
      availability: moduleAvailability[ModuleName.RISK_MAP_MODULE],
      isLoaded: Boolean(moduleAvailability[ModuleName.RISK_MAP_MODULE]),
    },
  ];

  // Load module availability data
  useEffect(() => {
    const loadModuleAvailability = async () => {
      // Load describe module availability (already implemented)
      if (!moduleAvailability[ModuleName.DESCRIBE_MODULE] && !loadingModules.has(ModuleName.DESCRIBE_MODULE)) {
        setLoadingModules(prev => new Set(prev).add(ModuleName.DESCRIBE_MODULE));
        try {
          const response = await getDescribeModuleOutputsAction(analysis.id);
          if (response.success && response.data && analysis.model_type) {
            const availability = response.data.model_specific_availability[analysis.model_type as keyof typeof response.data.model_specific_availability];
            setModuleAvailability(prev => ({
              ...prev,
              [ModuleName.DESCRIBE_MODULE]: availability,
            }));
          }
        } catch (error) {
          console.error("Failed to load describe module availability:", error);
        } finally {
          setLoadingModules(prev => {
            const newSet = new Set(prev);
            newSet.delete(ModuleName.DESCRIBE_MODULE);
            return newSet;
          });
        }
      }

      // Load estimate module availability
      if (!moduleAvailability[ModuleName.ESTIMATE_MODULE] && !loadingModules.has(ModuleName.ESTIMATE_MODULE)) {
        setLoadingModules(prev => new Set(prev).add(ModuleName.ESTIMATE_MODULE));
        try {
          const response = await getEstimateModuleOutputsAction(analysis.id);
          if (response.success && response.data && analysis.model_type) {
            const availability = response.data.model_specific_availability[analysis.model_type as keyof typeof response.data.model_specific_availability];
            setModuleAvailability(prev => ({
              ...prev,
              [ModuleName.ESTIMATE_MODULE]: availability,
            }));
          }
        } catch (error) {
          console.error("Failed to load estimate module availability:", error);
        } finally {
          setLoadingModules(prev => {
            const newSet = new Set(prev);
            newSet.delete(ModuleName.ESTIMATE_MODULE);
            return newSet;
          });
        }
      }

      // Load validate module availability
      if (!moduleAvailability[ModuleName.VALIDATE_MODULE] && !loadingModules.has(ModuleName.VALIDATE_MODULE)) {
        setLoadingModules(prev => new Set(prev).add(ModuleName.VALIDATE_MODULE));
        try {
          const response = await getValidateModuleOutputsAction(analysis.id);
          if (response && analysis.model_type) {
            const availability = response.model_specific_availability[analysis.model_type as keyof typeof response.model_specific_availability];
            setModuleAvailability(prev => ({
              ...prev,
              [ModuleName.VALIDATE_MODULE]: availability,
            }));
          }
        } catch (error) {
          console.error("Failed to load validate module availability:", error);
        } finally {
          setLoadingModules(prev => {
            const newSet = new Set(prev);
            newSet.delete(ModuleName.VALIDATE_MODULE);
            return newSet;
          });
        }
      }

      // Load risk map module availability
      if (!moduleAvailability[ModuleName.RISK_MAP_MODULE] && !loadingModules.has(ModuleName.RISK_MAP_MODULE)) {
        setLoadingModules(prev => new Set(prev).add(ModuleName.RISK_MAP_MODULE));
        try {
          const response = await getRiskMapModuleOutputsAction({
            analysis_id: analysis.id,
          });
          if (response.success && response.data && analysis.model_type) {
            const availability = response.data.model_specific_availability[analysis.model_type as keyof typeof response.data.model_specific_availability];
            setModuleAvailability(prev => ({
              ...prev,
              [ModuleName.RISK_MAP_MODULE]: availability,
            }));
          }
        } catch (error) {
          console.error("Failed to load risk map module availability:", error);
        } finally {
          setLoadingModules(prev => {
            const newSet = new Set(prev);
            newSet.delete(ModuleName.RISK_MAP_MODULE);
            return newSet;
          });
        }
      }
    };

    loadModuleAvailability();
  }, [analysis.id, analysis.model_type, moduleAvailability, loadingModules]);

  const isModuleAvailable = (module: ModuleInfo): boolean => {
    if (!module.availability) return false;
    
    // A module is available if at least one of its features is available
    return Object.values(module.availability).some(available => available);
  };

  const isCurrentModule = (modulePath: string): boolean => {
    return pathname === modulePath;
  };

  const getModuleIcon = (module: ModuleName) => {
    switch (module) {
      case ModuleName.LOAD_MODULE:
        return <Database className="w-4 h-4" />;
      case ModuleName.DESCRIBE_MODULE:
        return <BarChart3 className="w-4 h-4" />;
      case ModuleName.ESTIMATE_MODULE:
        return <Target className="w-4 h-4" />;
      case ModuleName.VALIDATE_MODULE:
        return <Shield className="w-4 h-4" />;
      case ModuleName.RISK_MAP_MODULE:
        return <Map className="w-4 h-4" />;
      default:
        return <Database className="w-4 h-4" />;
    }
  };

  const getModuleTitle = (module: ModuleName) => {
    switch (module) {
      case ModuleName.LOAD_MODULE:
        return "Data Module";
      case ModuleName.DESCRIBE_MODULE:
        return "Describe Module";
      case ModuleName.ESTIMATE_MODULE:
        return "Estimate Module";
      case ModuleName.VALIDATE_MODULE:
        return "Validate Module";
      case ModuleName.RISK_MAP_MODULE:
        return "Risk Map Module";
      default:
        return "Unknown Module";
    }
  };

  const getStatusIcon = (status: AnalyzeStatus) => {
    switch (status) {
      case AnalyzeStatus.COMPLETED:
        return <CheckCircle className="w-5 h-5" />;
      case AnalyzeStatus.IN_PROGRESS:
        return <Loader2 className="w-5 h-5 animate-spin" />;
      case AnalyzeStatus.ERROR:
        return <Clock className="w-5 h-5" />;
      default:
        return <Clock className="w-5 h-5" />;
    }
  };

  const allModules = [
    ModuleName.LOAD_MODULE,
    ModuleName.DESCRIBE_MODULE,
    ModuleName.ESTIMATE_MODULE,
    ModuleName.VALIDATE_MODULE,
    ModuleName.RISK_MAP_MODULE,
  ];

  return (
    <Card className="w-80 h-fit sticky top-6">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Database className="w-5 h-5" />
          Analysis Modules
        </CardTitle>
        <div className="text-sm text-muted-foreground">
          Model: <span className="font-medium">{analysis.model_type || 'Unknown'}</span>
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        <div className="space-y-2">
          {modules.map((module, index) => {
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
                        isCurrent ? "bg-primary text-primary-foreground" : "hover:bg-muted"
                      }`}
                    >
                      <div className="flex items-center gap-3 w-full">
                        <div className={`shrink-0 ${isCurrent ? "text-primary-foreground" : "text-primary"}`}>
                          {module.icon}
                        </div>
                        <div className="text-left flex-1 min-w-0">
                          <div className="font-medium truncate">{module.title}</div>
                          <div className={`text-xs truncate ${
                            isCurrent ? "text-primary-foreground/80" : "text-muted-foreground"
                          }`}>
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
                          {isLoading ? "Loading availability..." : "Not available for this model"}
                        </div>
                      </div>
                      <Badge variant="secondary" className="text-xs shrink-0">
                        N/A
                      </Badge>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <Separator className="my-4" />
        
        {/* Progress Overview */}
        <div className="space-y-2">
          <div className="text-sm font-medium mb-3">Progress Overview</div>
          {allModules.map((module, index) => {
            const isActive = analysis.current_module === module;
            const isCompleted = allModules.indexOf(analysis.current_module) > index;

            return (
              <div
                key={module}
                className={`flex items-center gap-2 p-2 rounded-md text-sm ${
                  isActive
                    ? "bg-blue-50 text-blue-700 border border-blue-200 dark:bg-blue-950 dark:text-blue-300 dark:border-blue-800"
                    : isCompleted
                    ? "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300"
                    : "text-gray-600 dark:text-gray-400"
                }`}
              >
                <div className="flex items-center justify-center w-6 h-6 rounded-full">
                  {getModuleIcon(module)}
                </div>
                <span className="flex-1">{getModuleTitle(module)}</span>
                {isCompleted && (
                  <CheckCircle className="w-4 h-4 text-green-600" />
                )}
              </div>
            );
          })}
        </div>

        <Separator className="my-4" />
        
        <div className="text-xs text-muted-foreground space-y-1">
          <div className="font-medium">Legend:</div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-primary rounded-full" />
            <span>Available & accessible</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-muted-foreground rounded-full" />
            <span>Not available for model</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
} 