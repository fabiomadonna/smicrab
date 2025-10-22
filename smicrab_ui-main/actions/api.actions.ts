"use server";

import { API_URL } from '@/constants/constants';
import { getAccessToken } from './auth.actions';
import { ApiResponse } from '@/types';

export async function request<T>(
  endpoint: string,
  options?: RequestInit,
  requireAuth: boolean = false
): Promise<ApiResponse<T>> {
  try {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    
    // Add any additional headers from options
    if (options?.headers) {
      Object.entries(options.headers).forEach(([key, value]) => {
        if (typeof value === 'string') {
          headers[key] = value;
        }
      });
    }

    if (requireAuth) {
      const accessToken = await getAccessToken();
      if (accessToken) {
        headers['Authorization'] = `Bearer ${accessToken}`;
      }
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
      headers,
      ...options,
    });

    const data = await response.json();
    if (!response.ok) {
      return { success: false, message: data.message || 'Request failed', code: response.status };
    }
    return data;
  } catch (error) {
    console.error("Request error:", error);
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}