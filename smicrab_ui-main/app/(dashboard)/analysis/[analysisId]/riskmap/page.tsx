import { notFound } from "next/navigation";
import { AnalysisBreadcrumb } from "@/components/analysis/analysis-breadcrumb";
import { RiskMapModuleClient } from "@/components/riskmap/riskmap-module-client";
import { getRiskMapModuleOutputsAction } from "@/actions/riskmap.actions";
import { getAnalysisContext } from "@/lib/analysis-cache";
import { ModuleName } from "@/types";

interface RiskMapModulePageProps {
  params: Promise<{
    analysisId: string;
  }>;
}

export default async function RiskMapModulePage({ params }: RiskMapModulePageProps) {
  const { analysisId } = await params;

  try {
    // Get analysis context
    const analysisContext = await getAnalysisContext(analysisId);
    
    if (!analysisContext) {
      notFound();
    }

    // Check if analysis is completed
    if (analysisContext.status !== "completed") {
      return (
        <div className="container mx-auto px-4 py-8">
          <AnalysisBreadcrumb
            analysisId={analysisId}
            currentModule={ModuleName.RISK_MAP_MODULE}
          />
          
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-yellow-800 mb-2">
              Analysis Not Complete
            </h2>
            <p className="text-yellow-700">
              The risk map module is only available for completed analyses. 
              Please complete your analysis first.
            </p>
          </div>
        </div>
      );
    }

    // Get risk map module outputs
    const response = await getRiskMapModuleOutputsAction({
      analysis_id: analysisId,
    });

    if (!response.success || !response.data) {
      return (
        <div className="container mx-auto px-4 py-8">
          <AnalysisBreadcrumb
            analysisId={analysisId}
            currentModule={ModuleName.RISK_MAP_MODULE}
          />
          
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-red-800 mb-2">
              Error Loading Risk Map Results
            </h2>
            <p className="text-red-700">
              {response.message || "Failed to load risk map module outputs"}
            </p>
          </div>
        </div>
      );
    }

    const { riskmap_module_outputs, model_specific_availability } = response.data;

    return (
      <div className="container mx-auto px-4 py-8">
        <AnalysisBreadcrumb
          analysisId={analysisId}
          currentModule={ModuleName.RISK_MAP_MODULE}
        />
        
        <div className="mb-6">
          <h1 className="text-2xl font-bold">
            Risk Map Module Results
          </h1>
          <p className="text-muted-foreground mt-2">
            Spatial and temporal risk analysis results for Analysis {analysisId.slice(-8)}
          </p>
        </div>

        <RiskMapModuleClient
          analysisId={analysisId}
          outputs={riskmap_module_outputs}
          modelAvailability={model_specific_availability}
          modelType={analysisContext.model_type}
          isDynamic={analysisContext.is_dynamic_output || false}
        />
      </div>
    );
  } catch (error) {
    console.error("Error loading risk map module page:", error);
    return (
      <div className="container mx-auto px-4 py-8">
        <AnalysisBreadcrumb
          analysisId={analysisId}
          currentModule={ModuleName.RISK_MAP_MODULE}
        />
        
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-lg font-semibold text-red-800 mb-2">
            Unexpected Error
          </h2>
          <p className="text-red-700">
            An unexpected error occurred while loading the risk map module.
          </p>
        </div>
      </div>
    );
  }
} 