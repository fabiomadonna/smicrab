import { unstable_cache } from 'next/cache';
import { AnalyzeStatus } from '@/types/enums';
import type { Analysis } from '@/types/analysis';
import { getAccessToken } from '@/actions/auth.actions';

// Cache tags for revalidation
export const ANALYSIS_CACHE_TAGS = {
  analysis: (analysisId: string) => `analysis:${analysisId}`,
  allAnalyses: 'analyses:all',
} as const;

/**
 * Get analysis from API (not cached)
 * Used internally by cache functions and for non-completed analyses
 */
async function fetchAnalysisFromAPI(analysisId: string, accessToken?: string): Promise<Analysis | null> {
  try {
    const { API_URL } = await import('@/constants/constants');
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    // Add authorization header if token is available
    if (accessToken) {
      headers['Authorization'] = `Bearer ${accessToken}`;
    }
    
    const response = await fetch(`${API_URL}/analysis/${analysisId}/status`, {
      method: 'GET',
      headers,
      // Important: Disable Next.js fetch cache for real-time data
      cache: 'no-store',
    });

    if (!response.ok) {
      console.error(`Failed to fetch analysis ${analysisId}: ${response.status}`);
      return null;
    }

    const result = await response.json();
    return result.data || null;
  } catch (error) {
    console.error('Error fetching analysis from API:', error);
    return null;
  }
}

/**
 * Next.js 15 cached function for COMPLETED analyses only
 * This will cache completed analyses indefinitely since they don't change
 * Note: Access token is passed as parameter to avoid cookies in cache scope
 */
const getCachedCompletedAnalysis = (analysisId: string, accessToken: string) => unstable_cache(
  async (): Promise<Analysis | null> => {
    const analysis = await fetchAnalysisFromAPI(analysisId, accessToken);
    
    // Only return cached result if analysis is completed
    // This ensures we only cache completed analyses
    if (analysis && analysis.status === AnalyzeStatus.COMPLETED) {
      return analysis;
    }
    
    return null;
  },
  [`completed-analysis-${analysisId}-${accessToken ? 'auth' : 'no-auth'}`],
  {
    tags: [ANALYSIS_CACHE_TAGS.analysis(analysisId)],
    revalidate: false, // Cache indefinitely for completed analyses
  }
)();

/**
 * Smart analysis retrieval function that uses cache strategy:
 * - For completed analyses: Use Next.js cache
 * - For in-progress/pending/error: Always fetch fresh data (no cache)
 */
export async function getAnalysisWithSmartCache(analysisId: string): Promise<Analysis | null> {
  // Get access token outside of cache scope
  const accessToken = await getAccessToken();
  
  // First, try to get from cache (only returns if completed)
  const cachedAnalysis = await getCachedCompletedAnalysis(analysisId, accessToken || '');
  
  if (cachedAnalysis) {
    return cachedAnalysis;
  }
  
  // If not in cache (or not completed), fetch fresh data
  const freshAnalysis = await fetchAnalysisFromAPI(analysisId, accessToken || undefined);
  
  if (!freshAnalysis) {
    return null;
  }
  
  // Note: We don't call revalidateAnalysisCache here during render
  // Cache invalidation should be handled by server actions after mutations
  
  return freshAnalysis;
}

/**
 * Get essential analysis context data with smart caching
 */
export interface AnalysisContext {
  id: string;
  model_type?: string;
  is_dynamic_output?: boolean;
  status: string;
  coordinates?: {
    latitude?: number;
    longitude?: number;
  };
  model_config_data?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export async function getAnalysisContext(analysisId: string): Promise<AnalysisContext | null> {
  const analysis = await getAnalysisWithSmartCache(analysisId);
  
  if (!analysis) {
    return null;
  }

  return {
    id: analysis.id,
    model_type: analysis.model_type,
    is_dynamic_output: analysis.is_dynamic_output,
    status: analysis.status,
    coordinates: analysis.coordinates,
    model_config_data: analysis.model_config_data,
    created_at: analysis.created_at,
    updated_at: analysis.updated_at,
  };
}

/**
 * Revalidate analysis cache
 */
export async function revalidateAnalysisCache(analysisId?: string) {
  const { revalidateTag } = await import('next/cache');
  
  if (analysisId) {
    revalidateTag(ANALYSIS_CACHE_TAGS.analysis(analysisId));
  } else {
    revalidateTag(ANALYSIS_CACHE_TAGS.allAnalyses);
  }
}

/**
 * Force refresh analysis data (bypass cache completely)
 * Use this for polling in-progress analyses
 */
export async function getAnalysisStatusRealTime(analysisId: string): Promise<Analysis | null> {
  const accessToken = await getAccessToken();
  return await fetchAnalysisFromAPI(analysisId, accessToken || undefined);
}

/**
 * Check if an analysis should be polled (not completed)
 */
export function shouldPollAnalysis(status: string): boolean {
  return status !== AnalyzeStatus.COMPLETED && 
         status !== AnalyzeStatus.ERROR;
}

/**
 * Utility to get analysis with polling logic
 * Returns { analysis, shouldContinuePolling }
 */
export async function getAnalysisWithPollingInfo(analysisId: string): Promise<{
  analysis: Analysis | null;
  shouldContinuePolling: boolean;
}> {
  const analysis = await getAnalysisWithSmartCache(analysisId);
  
  return {
    analysis,
    shouldContinuePolling: analysis ? shouldPollAnalysis(analysis.status) : false,
  };
} 