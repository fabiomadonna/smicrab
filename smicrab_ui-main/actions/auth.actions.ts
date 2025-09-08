"use server";
import { cookies } from 'next/headers';
import { z } from 'zod';
import { API_URL } from '@/constants/constants';
import { 
  LoginRequest, 
  LoginResponse, 
  RegisterRequest, 
  RegisterResponse, 
  RefreshTokenRequest, 
  RefreshTokenResponse, 
  UserProfileResponse,
  UserSession,
  loginSchema, 
  registerSchema, 
  refreshTokenSchema 
} from '@/types/auth';

// Cookie names
const ACCESS_TOKEN_COOKIE = 'smicrab_access_token';
const REFRESH_TOKEN_COOKIE = 'smicrab_refresh_token';
const USER_SESSION_COOKIE = 'smicrab_user_session';

// Set authentication cookies
async function setAuthCookies(
  accessToken: string,
  refreshToken: string,
  userSession: UserSession
): Promise<void> {
  const cookieStore = await cookies();
  
  cookieStore.set(ACCESS_TOKEN_COOKIE, accessToken, {
    httpOnly: true,
    // secure: process.env.NODE_ENV === 'production',
    secure: false,
    sameSite: 'lax',
    maxAge: 30 * 60, // 30 minutes
    path: '/',
  });

  cookieStore.set(REFRESH_TOKEN_COOKIE, refreshToken, {
    httpOnly: true,
    // secure: process.env.NODE_ENV === 'production',
    secure: false,
    sameSite: 'lax',
    maxAge: 7 * 24 * 60 * 60, // 7 days
    path: '/',
  });

  cookieStore.set(USER_SESSION_COOKIE, JSON.stringify(userSession), {
    httpOnly: false,
    // secure: process.env.NODE_ENV === 'production',
    secure: false,
    sameSite: 'lax',
    maxAge: 7 * 24 * 60 * 60, // 7 days
    path: '/',
  });
}

// Clear authentication cookies
async function clearAuthCookies(): Promise<void> {
  const cookieStore = await cookies();
  
  cookieStore.delete(ACCESS_TOKEN_COOKIE);
  cookieStore.delete(REFRESH_TOKEN_COOKIE);
  cookieStore.delete(USER_SESSION_COOKIE);
}

// Generic API request function for authentication
async function authRequest<T>(
  endpoint: string,
  options?: RequestInit
): Promise<{ success: boolean; data?: T; message: string; code?: number }> {
  try {
    const response = await fetch(`${API_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      ...options,
    });

    const data = await response.json();
    
    if (!response.ok) {
      return {
        success: false,
        message: data.message || 'Request failed',
        code: response.status,
      };
    }

    return data;
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// Login user
export async function loginUser(formData: FormData): Promise<{ success: boolean; message: string; redirectTo?: string }> {
  try {
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;
    const redirect = formData.get('redirect') as string;

    const data: LoginRequest = { email, password };
    const validatedData = loginSchema.parse(data);

    const response = await authRequest<LoginResponse>('/user/login', {
      method: 'POST',
      body: JSON.stringify(validatedData),
    });

    if (response.success && response.data) {
      const userSession: UserSession = {
        user_id: response.data.user_id,
        email: response.data.email,
        access_token: response.data.access_token,
        refresh_token: response.data.refresh_token,
      };

      await setAuthCookies(
        response.data.access_token,
        response.data.refresh_token,
        userSession
      );

      return { 
        success: true, 
        message: 'Login successful',
        redirectTo: redirect || '/dashboard'
      };
    }

    return { success: false, message: response.message };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        success: false,
        message: error.errors.map(err => `${err.path.join('.')}: ${err.message}`).join(', '),
      };
    }
    return { success: false, message: 'Login failed' };
  }
}

// Register user
export async function registerUser(formData: FormData): Promise<{ success: boolean; message: string }> {
  try {
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;
    const confirmPassword = formData.get('confirmPassword') as string;

    if (password !== confirmPassword) {
      return { success: false, message: 'Passwords do not match' };
    }

    const data: RegisterRequest = { email, password };
    const validatedData = registerSchema.parse(data);

    const response = await authRequest<RegisterResponse>('/user/register', {
      method: 'POST',
      body: JSON.stringify(validatedData),
    });

    if (response.success && response.data) {
      return { success: true, message: 'Registration successful' };
    }

    return { success: false, message: response.message };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        success: false,
        message: error.errors.map(err => `${err.path.join('.')}: ${err.message}`).join(', '),
      };
    }
    return { success: false, message: 'Registration failed' };
  }
}

// Get current user from session
export async function getCurrentUser(): Promise<UserSession | null> {
  try {
    const cookieStore = await cookies();
    const userSessionCookie = cookieStore.get(USER_SESSION_COOKIE);
    
    if (!userSessionCookie?.value) {
      return null;
    }

    const userSession: UserSession = JSON.parse(userSessionCookie.value);
    return userSession;
  } catch (error) {
    console.error('Error getting current user:', error);
    return null;
  }
}

// Get access token
export async function getAccessToken(): Promise<string | null> {
  try {
    const cookieStore = await cookies();
    const accessToken = cookieStore.get(ACCESS_TOKEN_COOKIE);
    if (accessToken?.value) {
      return accessToken.value;
    }
    
    const userSessionCookie = cookieStore.get(USER_SESSION_COOKIE);
    if (userSessionCookie?.value) {
      const userSession: UserSession = JSON.parse(userSessionCookie.value);
      return userSession.access_token;
    }
    
    return null;
  } catch (error) {
    console.error('Error getting access token:', error);
    return null;
  }
}

// Get user profile
export async function getUserProfile(): Promise<{ success: boolean; data?: UserProfileResponse; message: string }> {
  try {
    const response = await authRequest<UserProfileResponse>('/user/me', undefined);
    return response;
  } catch (error) {
    return { success: false, message: 'Failed to get user profile' };
  }
}

// Logout user
export async function logoutUser(): Promise<{ success: boolean; message: string }> {
  try {
    await clearAuthCookies();
    return { success: true, message: 'Logged out successfully' };
  } catch (error) {
    return { success: false, message: 'Logout failed' };
  }
} 