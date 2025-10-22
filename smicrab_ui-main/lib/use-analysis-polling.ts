"use client";

import { useState, useEffect, useCallback } from 'react';
import { Analysis } from '@/types/analysis';
import { AnalyzeStatus } from '@/types/enums';
import { getAnalysisStatusAction, getAnalysisStatusRealTimeAction, revalidateAnalysisCacheAction } from '@/actions/analysis.actions';

interface UseAnalysisPollingOptions {
  analysisId: string;
  pollingInterval?: number; // milliseconds, default 10000 (10 seconds)
  onStatusChange?: (analysis: Analysis) => void;
  onError?: (error: string) => void;
}

interface UseAnalysisPollingReturn {
  analysis: Analysis | null;
  isLoading: boolean;
  error: string | null;
  isPolling: boolean;
  startPolling: () => void;
  stopPolling: () => void;
  refreshNow: () => Promise<void>;
}

/**
 * Custom hook for analysis polling with smart caching strategy:
 * - Uses cache for initial load and completed analyses
 * - Polls real-time (bypassing cache) for in-progress analyses every 10 seconds
 * - Automatically stops polling when analysis is completed or failed
 */
export function useAnalysisPolling({
  analysisId,
  pollingInterval = 10000, // 10 seconds
  onStatusChange,
  onError,
}: UseAnalysisPollingOptions): UseAnalysisPollingReturn {
  const [analysis, setAnalysis] = useState<Analysis | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isPolling, setIsPolling] = useState(false);
  const [intervalId, setIntervalId] = useState<NodeJS.Timeout | null>(null);

  // Check if analysis should be polled
  const shouldPoll = useCallback((analysisStatus: string) => {
    return analysisStatus !== AnalyzeStatus.COMPLETED && 
           analysisStatus !== AnalyzeStatus.ERROR;
  }, []);

  // Fetch analysis using cache (for completed) or real-time (for in-progress)
  const fetchAnalysis = useCallback(async (useRealTime = false) => {
    try {
      setError(null);
      
      const response = useRealTime 
        ? await getAnalysisStatusRealTimeAction(analysisId)
        : await getAnalysisStatusAction(analysisId);

      if (response.success && response.data) {
        const newAnalysis = response.data;
        const previousStatus = analysis?.status;
        
        setAnalysis(newAnalysis);
        
        // If analysis just completed, invalidate cache to ensure it gets cached
        if (previousStatus && previousStatus !== AnalyzeStatus.COMPLETED && 
            newAnalysis.status === AnalyzeStatus.COMPLETED) {
          // Invalidate cache in the background (don't await to avoid blocking UI)
          revalidateAnalysisCacheAction(analysisId).catch(console.error);
        }
        
        // Notify parent component of status change
        if (onStatusChange) {
          onStatusChange(newAnalysis);
        }

        return newAnalysis;
      } else {
        const errorMsg = typeof response.error === 'string' 
          ? response.error 
          : 'Failed to fetch analysis';
        setError(errorMsg);
        if (onError) {
          onError(errorMsg);
        }
        return null;
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Unknown error occurred';
      setError(errorMsg);
      if (onError) {
        onError(errorMsg);
      }
      return null;
    }
  }, [analysisId, analysis?.status, onStatusChange, onError]);

  // Start polling function
  const startPolling = useCallback(() => {
    if (intervalId) {
      clearInterval(intervalId);
    }

    setIsPolling(true);
    
    const id = setInterval(async () => {
      const currentAnalysis = await fetchAnalysis(true); // Use real-time for polling
      
      // Stop polling if analysis is completed or failed
      if (currentAnalysis && !shouldPoll(currentAnalysis.status)) {
        setIsPolling(false);
        clearInterval(id);
        setIntervalId(null);
      }
    }, pollingInterval);

    setIntervalId(id);
  }, [fetchAnalysis, pollingInterval, shouldPoll, intervalId]);

  // Stop polling function
  const stopPolling = useCallback(() => {
    if (intervalId) {
      clearInterval(intervalId);
      setIntervalId(null);
    }
    setIsPolling(false);
  }, [intervalId]);

  // Refresh now function
  const refreshNow = useCallback(async () => {
    setIsLoading(true);
    await fetchAnalysis(true); // Use real-time for manual refresh
    setIsLoading(false);
  }, [fetchAnalysis]);

  // Initial load
  useEffect(() => {
    const loadInitialData = async () => {
      setIsLoading(true);
      const initialAnalysis = await fetchAnalysis(false); // Use cache for initial load
      
      // Start polling if analysis needs it
      if (initialAnalysis && shouldPoll(initialAnalysis.status)) {
        startPolling();
      }
      
      setIsLoading(false);
    };

    loadInitialData();

    // Cleanup on unmount
    return () => {
      stopPolling();
    };
  }, [analysisId]); // Only depend on analysisId, not fetchAnalysis to avoid infinite loops

  // Stop polling when component unmounts or analysis ID changes
  useEffect(() => {
    return () => {
      stopPolling();
    };
  }, [stopPolling]);

  return {
    analysis,
    isLoading,
    error,
    isPolling,
    startPolling,
    stopPolling,
    refreshNow,
  };
} 