import { notFound } from "next/navigation";
import { AnalysisBreadcrumb } from "@/components/analysis/analysis-breadcrumb";
import { ValidateModuleClient } from "@/components/validate/validate-module-client";
import { getAnalysisContext } from "@/lib/analysis-cache";
import { getValidateModuleOutputsAction } from "@/actions/validate.actions";
import { ModuleName, AnalyzeStatus, ModelType } from "@/types/enums";

interface ValidatePageProps {
  params: Promise<{ analysisId: string }>;
}

export default async function ValidatePage({ params }: ValidatePageProps) {
  const { analysisId } = await params;

  // Get analysis context from cache to verify the analysis exists and is accessible
  const analysisContext = await getAnalysisContext(analysisId);
  
  if (!analysisContext) {
    notFound();
  }

  // Check if analysis is completed - validate module should only be available for completed analyses
  if (analysisContext.status !== AnalyzeStatus.COMPLETED) {
    notFound();
  }

  // Get validate module outputs
  const validateResponse = await getValidateModuleOutputsAction(analysisId);
  
  if (!validateResponse) {
    notFound();
  }

  return (
    <div className="container mx-auto px-4 py-6">
      <AnalysisBreadcrumb 
        analysisId={analysisId}
        currentModule={ModuleName.VALIDATE_MODULE}
      />
      
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Validate Module Results</h1>
        <p className="text-muted-foreground mt-2">
          Validation results and diagnostic statistics for the estimated model
        </p>
      </div>

      <ValidateModuleClient
        analysisId={analysisId}
        outputs={validateResponse.validate_module_outputs}
        modelAvailability={validateResponse.model_specific_availability}
        modelType={analysisContext.model_type as ModelType}
        isDynamic={analysisContext.is_dynamic_output || false}
      />
    </div>
  );
} 