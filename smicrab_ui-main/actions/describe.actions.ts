"use server";

import { revalidatePath } from "next/cache";
import { GetDescribeModuleOutputsResponse } from "@/types/describe";
import { ApiResponse } from "@/types";
import { request } from "./api.actions";

/**
 * Get describe module outputs for a specific analysis
 */
export async function getDescribeModuleOutputsAction(
  analysisId: string
): Promise<ApiResponse<GetDescribeModuleOutputsResponse>> {
  try {
    const result = await request<GetDescribeModuleOutputsResponse>(`/describe_module/outputs?analysis_id=${analysisId}`, undefined, true); // Require authentication

    if (!result.success) {
      return {
        success: false,
        message: result.message || "Failed to get describe module outputs",
      };
    }

    return {
      success: true,
      data: result.data,
      message: result.message,
    };
  } catch (error) {
    console.error("Error getting describe module outputs:", error);
    return {
      success: false,
      message: error instanceof Error ? error.message : "An unexpected error occurred",
    };
  }
}

/**
 * Revalidate paths for the describe module
 */
export async function revalidateDescribeModulePaths(analysisId: string) {
  revalidatePath(`/analysis/${analysisId}`);
  revalidatePath(`/analysis/${analysisId}/describe`);
} 