"use server";

import { API_URL } from "@/constants/constants";
import { ApiResponse } from "@/types";
import { 
  Dataset
} from "@/types/dataset";


/**
 * Fetch list of available datasets
 */
export async function fetchDatasets(): Promise<ApiResponse<Dataset[]>> {
  try {
    const response = await fetch(`${API_URL}/datasets`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching datasets:', error);
    throw error;
  }
}


/**
 * Fetch list of available rasters
 */
export async function fetchRasters(): Promise<ApiResponse<Dataset[]>> {
  try {
    const response = await fetch(`${API_URL}/datasets/rasters`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching datasets:', error);
    throw error;
  }
}
