"""
Authentication middleware for SMICRAB backend.
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import time
from typing import List

from app.utils.auth import AuthUtils
from app.utils.logger import Logger
from app.utils.api_response import APIResponse


class AuthMiddleware(BaseHTTPMiddleware):
    """Middleware for JWT authentication."""
    
    def __init__(self, app, protected_paths: List[str] = None, exclude_paths: List[str] = None):
        super().__init__(app)
        self.protected_paths = protected_paths or [
            "/api/v1/analysis",
            "/api/v1/describe_module",
            "/api/v1/estimate_module", 
            "/api/v1/validate_module",
            "/api/v1/risk_map_module",
            "/api/v1/user/me"
        ]
        self.exclude_paths = exclude_paths or [
            "/api/v1/user/register",
            "/api/v1/user/login", 
            "/api/v1/user/refresh",
            "/api/v1/user/create",
            "/api/v1/analysis/webhook/completion",  # Webhook endpoint for containers
            "/health",
            "/docs",
            "/redoc",
            "/openapi.json"
        ]

    
    async def dispatch(self, request: Request, call_next):
        """Process the request and add authentication if needed."""
        start_time = time.time()
        
        # Check if path requires authentication
        path = request.url.path
        
        # Skip authentication for excluded paths
        if any(path.startswith(exclude_path) for exclude_path in self.exclude_paths):
            response = await call_next(request)
            return response
        
        # Check if path is protected
        if any(path.startswith(protected_path) for protected_path in self.protected_paths):
            try:
                # Get authorization header
                auth_header = request.headers.get("Authorization")
                if not auth_header:
                    return APIResponse.send_error(message="Authorization header missing", code=401, headers={"WWW-Authenticate": "Bearer"})
                
                # Extract token
                if not auth_header.startswith("Bearer "):
                    return APIResponse.send_error(message="Invalid authorization header format", code=401, headers={"WWW-Authenticate": "Bearer"})
                
                token = auth_header.split(" ")[1]
                
                # Verify token
                try:
                    payload = AuthUtils.verify_token_silent(token)
                except ValueError:
                    return APIResponse.send_error(message="Could not validate credentials", code=401, headers={"WWW-Authenticate": "Bearer"})
                
                # Add user info to request state
                request.state.user_id = payload.get("sub")
                request.state.user_email = payload.get("email")
                
                # Log successful authentication
                Logger.info(
                    f"User authenticated: {payload.get('email')} - User ID: {payload.get('sub')}, Path: {path}, Method: {request.method}"
                )
                
            except Exception as e:
                Logger.error(
                    f"Authentication error: {str(e)} - Path: {path}, Method: {request.method}",
                    context={"path": path, "method": request.method}
                )
                return APIResponse.send_error(message="Authentication failed", code=401, headers={"WWW-Authenticate": "Bearer"})
        
        # Process the request
        response = await call_next(request)
        
        # Add processing time header
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Simple rate limiting middleware."""
    
    def __init__(self, app, requests_per_minute: int = 60):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
        self.request_counts = {}
    
    async def dispatch(self, request: Request, call_next):
        """Process the request with rate limiting."""
        # Get client IP
        client_ip = request.client.host
        
        # Simple rate limiting (in production, use Redis)
        current_time = int(time.time() / 60)  # Minute-based window
        
        if client_ip not in self.request_counts:
            self.request_counts[client_ip] = {}
        
        if current_time not in self.request_counts[client_ip]:
            self.request_counts[client_ip][current_time] = 0
        
        self.request_counts[client_ip][current_time] += 1
        
        # Check rate limit
        if self.request_counts[client_ip][current_time] > self.requests_per_minute:
            return APIResponse.send_error(message="Rate limit exceeded", code=429, headers={"WWW-Authenticate": "Bearer"})
        
        # Clean up old entries
        old_times = [t for t in self.request_counts[client_ip].keys() if t < current_time - 1]
        for old_time in old_times:
            del self.request_counts[client_ip][old_time]
        
        response = await call_next(request)
        return response 