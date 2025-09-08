import { notFound } from "next/navigation";
import { AnalysisBreadcrumb } from "@/components/analysis/analysis-breadcrumb";
import { getAnalysisContext } from "@/lib/analysis-cache";
import { getEstimateModuleOutputsAction } from "@/actions/estimate.actions";
import { ModuleName, AnalyzeStatus, ModelType } from "@/types/enums";
import { EstimateModuleClient } from "@/components/estimate";

interface PageProps {
  params: Promise<{ analysisId: string }>;
}

export default async function EstimateModulePage({ params }: PageProps) {
  const { analysisId } = await params;

  // Get analysis context from cache to verify the analysis exists and is accessible
  const analysisContext = await getAnalysisContext(analysisId);
  
  if (!analysisContext) {
    notFound();
  }

  // Check if analysis is completed - estimate module should only be available for completed analyses
  if (analysisContext.status !== AnalyzeStatus.COMPLETED) {
    notFound();
  }

  // Get estimate module outputs
  const estimateResponse = await getEstimateModuleOutputsAction(analysisId);
  
  if (!estimateResponse.success || !estimateResponse.data) {
    notFound();
  }

  return (
    <div className="container mx-auto px-4 py-6">
      <AnalysisBreadcrumb 
        analysisId={analysisId}
        currentModule={ModuleName.ESTIMATE_MODULE}
      />
      
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Estimate Module Results</h1>
        <p className="text-muted-foreground mt-2">
          Explore estimation results through coefficient tables, spatial plots, and time series analysis
        </p>
      </div>

      <EstimateModuleClient
        analysisId={analysisId}
        outputs={estimateResponse.data.estimate_module_outputs}
        modelAvailability={estimateResponse.data.model_specific_availability}
        modelType={analysisContext.model_type as ModelType}
        isDynamic={analysisContext.is_dynamic_output || false}
      />
    </div>
  );
} 