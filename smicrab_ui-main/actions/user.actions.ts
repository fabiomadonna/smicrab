'use server';

import { 
  ApiResponse,
  RegisterResponse
} from '@/types';
import { registerUser } from './auth.actions';

/**
 * Create a new user
 */
export async function createUser(
  email: string,
  password: string
): Promise<ApiResponse<RegisterResponse>> {
  // Create a FormData object to match the auth action signature
  const formData = new FormData();
  formData.append('email', email);
  formData.append('password', password);
  
  return registerUser(formData);
} 