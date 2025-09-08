"use server";

import { revalidatePath } from "next/cache";
import { 
  CreateAnalysisRequest,
  UserAnalysesResponseData,
  SaveAnalysisParametersRequest,
  RunAnalysisRequest,
  RunAnalysisResponseData,
  DeleteAnalysisResponseData,
  Analysis
} from "@/types/analysis";
import { request } from "./api.actions";
import { 
  getAnalysisWithSmartCache, 
  getAnalysisStatusRealTime, 
  revalidateAnalysisCache 
} from "@/lib/analysis-cache";

// Common API Response type
interface ActionResponse<T> {
  success: boolean;
  data?: T;
  error?: string | { field: string; message: string }[];
  message?: string;
}

/**
 * Create a new analysis session
 */
export async function createAnalysisAction(
  userId: string
): Promise<ActionResponse<Analysis>> {
  try {
    const requestData: CreateAnalysisRequest = {
      user_id: userId
    };

    const result = await request<Analysis>('/analysis/create', {
      method: "POST",
      body: JSON.stringify(requestData),
    }, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        error: result.message || "Failed to create analysis",
      };
    }

    // Revalidate analyses list
    revalidatePath("/analyses");

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error creating analysis:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Get all analyses for a specific user
 */
export async function getUserAnalysesAction(userId: string): Promise<ActionResponse<Analysis[]>> {
  try {
    console.log("Getting analyses for user:", userId);
    
    const result = await request<UserAnalysesResponseData>(`/analysis/user/${userId}`, undefined, true);
    
    if (result.success && result.data) {
      return { 
        success: true, 
        data: result.data.analyses, 
        message: "Analyses retrieved successfully" 
      };
    } else {
      return { 
        success: false, 
        error: result.message || "Failed to retrieve analyses" 
      };
    }
  } catch (error) {
    console.error("Error in getUserAnalysesAction:", error);
    return { 
      success: false, 
      error: "An error occurred while retrieving analyses" 
    };
  }
}

/**
 * Save analysis parameters
 */
export async function saveAnalysisParametersAction(
  parameters: SaveAnalysisParametersRequest
): Promise<ActionResponse<Analysis>> {
  try {
    const result = await request<Analysis>('/analysis/parameters', {
      method: "POST",
      body: JSON.stringify(parameters),
    }, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        error: result.message || "Failed to save analysis parameters",
      };
    }

    // Invalidate cache and revalidate paths
    await revalidateAnalysisCache(parameters.analysis_id);
    revalidatePath(`/analysis/${parameters.analysis_id}`);
    revalidatePath("/analyses");

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error saving analysis parameters:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Run analysis with specified parameters
 */
export async function runAnalysisAction(
  requestData: RunAnalysisRequest
): Promise<ActionResponse<RunAnalysisResponseData>> {
  try {
    const result = await request<RunAnalysisResponseData>('/analysis/run', {
      method: "POST",
      body: JSON.stringify(requestData),
    }, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        error: result.message || "Failed to run analysis",
      };
    }

    // Invalidate cache and revalidate paths
    await revalidateAnalysisCache(requestData.analysis_id);
    revalidatePath(`/analysis/${requestData.analysis_id}`);
    revalidatePath("/analyses");

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error running analysis:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Get analysis status with Next.js 15 smart caching
 * Uses cache strategy:
 * - Caches completed analyses indefinitely
 * - Always fetches fresh data for in-progress/pending/error analyses
 */
export async function getAnalysisStatusAction(
  analysisId: string
): Promise<ActionResponse<Analysis>> {
  try {
    // Use smart cache strategy
    const analysis = await getAnalysisWithSmartCache(analysisId);

    if (!analysis) {
      return {
        success: false,
        error: "Analysis not found",
      };
    }

    return {
      success: true,
      data: analysis,
      message: "Analysis status retrieved successfully",
    };
  } catch (error) {
    console.error("Error getting analysis status:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Get analysis status in real-time (bypasses cache completely)
 * Use this for polling in-progress analyses every 10 seconds
 */
export async function getAnalysisStatusRealTimeAction(
  analysisId: string
): Promise<ActionResponse<Analysis>> {
  try {
    // Bypass cache completely for real-time data
    const analysis = await getAnalysisStatusRealTime(analysisId);

    if (!analysis) {
      return {
        success: false,
        error: "Analysis not found",
      };
    }

    return {
      success: true,
      data: analysis,
      message: "Real-time analysis status retrieved successfully",
    };
  } catch (error) {
    console.error("Error getting real-time analysis status:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Refresh analyses list for a user
 */
export async function refreshAnalysesAction(userId: string): Promise<ActionResponse<Analysis[]>> {
  try {
    revalidatePath('/');
    revalidatePath('/analyses');
    return await getUserAnalysesAction(userId);
  } catch (error) {
    console.error('Error refreshing analyses:', error);
    return {
      success: false,
      error: 'Failed to refresh analyses',
    };
  }
}

/**
 * Revalidate analysis cache when analysis status changes
 * This should be called from client components when they detect status changes
 */
export async function revalidateAnalysisCacheAction(
  analysisId: string
): Promise<ActionResponse<void>> {
  try {
    await revalidateAnalysisCache(analysisId);
    
    // Also revalidate related paths
    revalidatePath(`/analysis/${analysisId}`);
    revalidatePath('/analyses');
    
    return {
      success: true,
      message: 'Cache revalidated successfully',
    };
  } catch (error) {
    console.error('Error revalidating analysis cache:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "Failed to revalidate cache",
    };
  }
}

/**
 * Delete an analysis and clean up associated resources
 */
export async function deleteAnalysisAction(
  analysisId: string
): Promise<ActionResponse<DeleteAnalysisResponseData>> {
  try {
    const result = await request<DeleteAnalysisResponseData>(`/analysis/${analysisId}`, {
      method: "DELETE",
    }, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        error: result.message || "Failed to delete analysis",
      };
    }

    // Revalidate analyses list and related paths
    revalidatePath("/analyses");
    revalidatePath("/");
    await revalidateAnalysisCache(analysisId);

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error deleting analysis:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
} 