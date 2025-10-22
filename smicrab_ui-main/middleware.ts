import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const protectedRoutes = [
  '/dashboard',
  '/analyses',
  '/analysis',
  '/datasets',
];

const publicRoutes = [
  '/',
  '/login',
  '/register',
];

const API_URL = process.env.API_URL || 'http://localhost:8000/api/v1';

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Skip middleware for API routes and static files
  if (pathname.startsWith('/api') || pathname.startsWith('/_next') || pathname.includes('.')) {
    return NextResponse.next();
  }

  const isProtectedRoute = protectedRoutes.some(route => pathname.startsWith(route));
  const isPublicRoute = publicRoutes.some(route => pathname === route);
  
  // Check if user has a session
  const userSessionCookie = request.cookies.get('smicrab_user_session')?.value;
  const refreshTokenCookie = request.cookies.get('smicrab_refresh_token')?.value;

  // If accessing protected route without session, redirect to login
  if (isProtectedRoute && !userSessionCookie) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // If accessing login/register with valid session, redirect to dashboard
  if (isPublicRoute && userSessionCookie) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  // For protected routes with session, check if access token is expired
  if (isProtectedRoute && userSessionCookie && refreshTokenCookie) {
    try {
      // Parse user session to check access token expiration
      const userSession = JSON.parse(userSessionCookie);
      const accessToken = userSession.access_token;
      
      if (accessToken) {
        // Decode JWT to check expiration (without verification)
        const payload = JSON.parse(Buffer.from(accessToken.split('.')[1], 'base64').toString());
        const currentTime = Math.floor(Date.now() / 1000);
        
        // If token is expired or will expire in next 5 minutes, refresh it
        if (payload.exp && payload.exp < (currentTime + 300)) {
          console.log('Access token expired or expiring soon, refreshing...');
          
          try {
            // Attempt to refresh the token
            const refreshResponse = await fetch(`${API_URL}/user/refresh`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                refresh_token: refreshTokenCookie
              })
            });

            if (refreshResponse.ok) {
              const refreshData = await refreshResponse.json();
              
              if (refreshData.success && refreshData.data) {
                // Create response with updated cookies
                const response = NextResponse.next();
                
                // Update access token cookie
                response.cookies.set('smicrab_access_token', refreshData.data.access_token, {
                  httpOnly: true,
                  secure: process.env.NODE_ENV === 'production',
                  sameSite: 'lax',
                  maxAge: 30 * 60, // 30 minutes
                  path: '/',
                });

                // Update user session cookie
                const updatedUserSession = {
                  ...userSession,
                  access_token: refreshData.data.access_token,
                };
                
                response.cookies.set('smicrab_user_session', JSON.stringify(updatedUserSession), {
                  httpOnly: false,
                  secure: process.env.NODE_ENV === 'production',
                  sameSite: 'lax',
                  maxAge: 7 * 24 * 60 * 60, // 7 days
                  path: '/',
                });

                console.log('Token refreshed successfully in middleware');
                return response;
              }
            }
          } catch (error) {
            console.error('Failed to refresh token in middleware:', error);
          }
          
          // If refresh failed, redirect to login
          const loginUrl = new URL('/login', request.url);
          loginUrl.searchParams.set('redirect', pathname);
          return NextResponse.redirect(loginUrl);
        }
      }
    } catch (error) {
      console.error('Error parsing user session in middleware:', error);
      // If session is invalid, redirect to login
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('redirect', pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|public).*)',
  ],
}; 