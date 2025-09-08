import { notFound } from "next/navigation";
import { AnalysisBreadcrumb } from "@/components/analysis/analysis-breadcrumb";
import { getAnalysisContext } from "@/lib/analysis-cache";
import { getDescribeModuleOutputsAction } from "@/actions/describe.actions";
import { ModuleName, AnalyzeStatus, ModelType } from "@/types/enums";
import { DescribeModuleClient } from "@/components/describe";

interface PageProps {
  params: Promise<{ analysisId: string }>;
}

export default async function DescribeModulePage({ params }: PageProps) {
  const { analysisId } = await params;

  // Get analysis context from cache to verify the analysis exists and is accessible
  const analysisContext = await getAnalysisContext(analysisId);
  
  if (!analysisContext) {
    notFound();
  }

  // Check if analysis is completed - describe module should only be available for completed analyses
  if (analysisContext.status !== AnalyzeStatus.COMPLETED) {
    notFound();
  }

  // Get describe module outputs
  const describeResponse = await getDescribeModuleOutputsAction(analysisId);
  
  if (!describeResponse.success || !describeResponse.data) {
    notFound();
  }

  return (
    <div className="container mx-auto px-4 py-6">
      <AnalysisBreadcrumb 
        analysisId={analysisId}
        currentModule={ModuleName.DESCRIBE_MODULE}
      />
      
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Describe Module Results</h1>
        <p className="text-muted-foreground mt-2">
          Explore data through plots showing variable behavior over time and space
        </p>
      </div>

      <DescribeModuleClient
        analysisId={analysisId}
        outputs={describeResponse.data.describe_module_outputs}
        modelAvailability={describeResponse.data.model_specific_availability}
        modelType={analysisContext.model_type as ModelType}
        isDynamic={analysisContext.is_dynamic_output || false}
      />
    </div>
  );
} 