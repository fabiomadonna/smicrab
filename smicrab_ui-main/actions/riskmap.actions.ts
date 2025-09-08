"use server";

import { 
  GetRiskMapOutputsRequest, 
  GetRiskMapOutputsResponse 
} from "@/types/riskmap";
import { ApiResponse } from "@/types/api";
import { request } from "./api.actions";

/**
 * Get risk map module outputs for a specific analysis
 */
export async function getRiskMapModuleOutputsAction(
  requestData: GetRiskMapOutputsRequest
): Promise<ApiResponse<GetRiskMapOutputsResponse>> {
  try {
    const result = await request<GetRiskMapOutputsResponse>(`/risk_map_module/outputs?analysis_id=${requestData.analysis_id}`, {
      cache: "no-store",
    }, true); // Require authentication

    return result;
  } catch (error) {
    console.error("Error fetching risk map module outputs:", error);
    return {
      success: false,
      data: undefined,
      message: error instanceof Error ? error.message : "Failed to fetch risk map module outputs",
    };
  }
} 