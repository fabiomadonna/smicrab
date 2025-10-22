import { z } from "zod";

// Authentication API Response types matching backend
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user_id: string;
  email: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
}

export interface RegisterResponse {
  user_id: string;
  email: string;
  created_at: string;
}

export interface RefreshTokenRequest {
  refresh_token: string;
}

export interface RefreshTokenResponse {
  access_token: string;
  token_type: string;
}

export interface UserProfileResponse {
  user_id: string;
  email: string;
  created_at: string;
}

// Zod schemas for validation
export const loginSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z.string().min(8, "Password must be at least 8 characters long"),
});

export const registerSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z.string().min(8, "Password must be at least 8 characters long"),
});

export const refreshTokenSchema = z.object({
  refresh_token: z.string().min(1, "Refresh token is required"),
});

// User session type
export interface UserSession {
  user_id: string;
  email: string;
  access_token: string;
  refresh_token: string;
}

// Authentication state type
export interface AuthState {
  user: UserSession | null;
  isLoading: boolean;
  isAuthenticated: boolean;
} 