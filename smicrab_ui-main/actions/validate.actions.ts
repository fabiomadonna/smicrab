"use server";

import { GetValidateOutputsResponse } from "@/types/validate";
import { ApiResponse } from "@/types";
import { request } from "./api.actions";

export async function getValidateModuleOutputsAction(
  analysisId: string
): Promise<GetValidateOutputsResponse> {
  try {
    const response = await request<GetValidateOutputsResponse>(
      `/validate_module/outputs?analysis_id=${analysisId}`,
      {
        method: "GET",
      },
      true // Require authentication
    );

    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch validate module outputs');
    }

    return response.data!;
  } catch (error) {
    console.error("Error fetching validate module outputs:", error);
    throw error;
  }
} 