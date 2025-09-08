"use server";

import { revalidatePath } from "next/cache";
import { GetEstimateModuleOutputsResponse } from "@/types/estimate";
import { ApiResponse } from "@/types";
import { request } from "./api.actions";

/**
 * Get estimate module outputs for a specific analysis
 */
export async function getEstimateModuleOutputsAction(
  analysisId: string
): Promise<ApiResponse<GetEstimateModuleOutputsResponse>> {
  try {
    const result = await request<GetEstimateModuleOutputsResponse>(`/estimate_module/outputs?analysis_id=${analysisId}`, undefined, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        message: result.message || "Failed to get estimate module outputs",
      };
    }

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error getting estimate module outputs:", error);
    return {
      success: false,
      message: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Revalidate paths for the estimate module
 */
export async function revalidateEstimateModulePaths(analysisId: string) {
  revalidatePath(`/analysis/${analysisId}`);
  revalidatePath(`/analysis/${analysisId}/estimate`);
} 