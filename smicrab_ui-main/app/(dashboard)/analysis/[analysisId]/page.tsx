import { notFound } from "next/navigation";
import { AnalysisClient } from "@/components/analysis/analysis-client";
import { getAnalysisStatusAction } from "@/actions";

export const dynamic = 'force-dynamic';

interface PageProps {
  params: Promise<{ analysisId: string }>;
}

export default async function AnalysisPage({ params }: PageProps) {
  const { analysisId } = await params;

  // Get initial analysis status
  const response = await getAnalysisStatusAction(analysisId);
  
  if (!response.success || !response.data) {
    notFound();
  }

  return (
    <AnalysisClient 
      analysisId={analysisId}
      initialAnalysis={response.data}
    />
  );
} 